#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Filename: axdl_tool.py
Description: python tool for flashing AXDL firmware.

Author: Hanxiao Dianjixz
Email: support@M5Stack.com
Created Date: 2025-02-12
Version: 1.0.1

# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT

use: sudo python3 axdl_tool.py --axp ./M5_LLM_ubuntu22.04_20250210.axp

"""
import argparse
import logging
import os
from pathlib import Path
import struct
import sys
import time
from tqdm import tqdm
import xml.etree.ElementTree as ET
import zipfile
import tempfile
import usb.core
import usb.util
import glob

tempfile.tempdir = "/var/tmp"

# ======= Global Definitions =======
CMD_HANDSHAKE_BYTE = 0x3C

BSL_CMD_CONNECT = 0x00
BSL_CMD_START_DATA = 0x01
BSL_CMD_MIDST_DATA = 0x02
BSL_CMD_ENDED_DATA = 0x03
BSL_CMD_EXEC_DATA = 0x04
BSL_CMD_RESET = 0x05
BSL_CMD_ERASE_FLASH = 0x0A
BSL_CMD_REPARTITION = 0x0B

BSL_REP_ACK = 0x80
BSL_REP_FLASH_DATA = 0x93
BSL_REP_VER = 0x81


# ======= USBSerialPort Class =======


class USBSerialPort:

    def __init__(self, vid, pid, logger=None, interface_number=0, alt_setting=0):
        """
        Constructor to store vid/pid and optional logger.

        :param vid: Vendor ID in integer form
        :param pid: Product ID in integer form
        :param logger: A logging.Logger instance or None
        :param interface_number: Which interface to claim (defaults to 0)
        :param alt_setting: Which alternate setting to select (defaults to 0)
        """
        self.vid = vid
        self.pid = pid
        self.logger = logger if logger else logging.getLogger("USBSerialPort")
        self.dev = None
        self.ep_out = None
        self.ep_in = None

        self.intf_num = interface_number
        self.alt_setting = alt_setting

        self.is_open = False
        self._kernel_driver_detached = False

    def open(self, retry_count=15):
        """
        Find the device, set configuration, claim the interface,
        and locate the Bulk endpoints (0x01 for OUT, 0x81 for IN).

        :param retry_count: Number of times to retry finding the device

        :raises usb.core.USBError: If there is a failure in USB communication
        :raises ValueError: If device or endpoints can't be found
        """
        self.logger.info(
            f"Attempting to open USB device (VID=0x{self.vid:04X}, PID=0x{self.pid:04X})"
        )

        # Find the USB device
        retry = 0
        while retry < retry_count:
            try:
                self.dev = usb.core.find(idVendor=self.vid, idProduct=self.pid)
                if self.dev is not None:
                    break
            except usb.core.USBError as e:
                self.logger.warning(f"USB find error: {e}")
            retry += 1
            self.logger.info("Retrying...")
            time.sleep(1)

        if self.dev is None:
            msg = f"Device not found (VID=0x{self.vid:04X}, PID=0x{self.pid:04X})."
            self.logger.error(msg)
            raise ValueError(msg)

        # Detach kernel driver if necessary
        try:
            if self.dev.is_kernel_driver_active(self.intf_num):
                self.dev.detach_kernel_driver(self.intf_num)
                self._kernel_driver_detached = True
                self.logger.debug(
                    f"Kernel driver detached from interface {self.intf_num}"
                )
        except (usb.core.USBError, NotImplementedError) as e:
            self.logger.warning(f"Could not detach kernel driver: {e}")

        # Set the active configuration
        try:
            self.dev.set_configuration()
        except usb.core.USBError as e:
            self.logger.warning(
                f"set_configuration() failed or might not be needed: {e}"
            )

        # Retrieve the active configuration and interface
        cfg = self.dev.get_active_configuration()
        try:
            intf = cfg[(self.intf_num, self.alt_setting)]
        except KeyError:
            msg = (
                f"No matching interface (number={self.intf_num}, alt={self.alt_setting}) "
                f"for device (VID=0x{self.vid:04X}, PID=0x{self.pid:04X})."
            )
            self.logger.error(msg)
            raise ValueError(msg)

        # Claim the interface
        try:
            usb.util.claim_interface(self.dev, intf.bInterfaceNumber)
        except usb.core.USBError as e:
            msg = f"Could not claim interface {intf.bInterfaceNumber}: {e}"
            self.logger.error(msg)
            raise

        # Locate Bulk endpoints
        self.ep_out = usb.util.find_descriptor(intf, bEndpointAddress=0x01)
        self.ep_in = usb.util.find_descriptor(intf, bEndpointAddress=0x81)
        if not self.ep_out or not self.ep_in:
            msg = "Could not locate Bulk endpoints 0x01 (OUT) and 0x81 (IN)."
            self.logger.error(msg)
            self.close()  # Clean up if partial success
            raise ValueError(msg)

        self.is_open = True
        self.logger.info(
            "USBSerialPort open: Bulk OUT=0x01, IN=0x81 claimed successfully."
        )

    def close(self):
        """
        Release the interface and dispose resources.
        Reattach kernel driver if it was originally attached.
        """
        if self.is_open and self.dev:
            try:
                usb.util.release_interface(self.dev, self.intf_num)
                self.logger.debug(f"Released interface {self.intf_num}")
            except usb.core.USBError as e:
                self.logger.warning(f"Error releasing interface {self.intf_num}: {e}")

            usb.util.dispose_resources(self.dev)

            # Optionally reattach the kernel driver if it was originally attached
            if self._kernel_driver_detached:
                try:
                    self.dev.attach_kernel_driver(self.intf_num)
                    self.logger.debug(
                        f"Reattached kernel driver to interface {self.intf_num}"
                    )
                except (usb.core.USBError, NotImplementedError) as e:
                    self.logger.warning(f"Could not reattach kernel driver: {e}")

            self.dev = None
            self.is_open = False
            self.logger.info("USBSerialPort closed.")

    def write(self, data: bytes, timeout=2000):
        """
        Write raw bytes to the Bulk OUT endpoint.

        :param data: Bytes to send
        :param timeout: Write timeout in milliseconds
        :raises IOError: If the port is not open
        :raises usb.core.USBError: For any USB communication error
        """
        if not self.is_open:
            raise IOError("Cannot write: USBSerialPort is not open.")
        try:
            self.ep_out.write(data, timeout=timeout)
            self.logger.debug(f"Wrote {len(data)} bytes to endpoint 0x01")
            # Print hex format for debugging
            if len(data) < 128:
                self.logger.debug("> " + " ".join(f"{b:02X}" for b in data))
            else:
                self.logger.debug(
                    f"> (First 128 bytes) {' '.join(f'{b:02X}' for b in data[:128])}"
                )
        except usb.core.USBError as e:
            self.logger.error(f"Write failed: {e}")
            raise

    def read(self, size=512, timeout=120000) -> bytes:
        """
        Read raw bytes from the Bulk IN endpoint.

        :param size: Maximum number of bytes to read
        :param timeout: Timeout in milliseconds
        :return: The bytes object read (could be empty if no data or if a timeout occurred)
        :raises IOError: If the port is not open
        :raises usb.core.USBError: For any USB communication error other than timeout
        """
        if not self.is_open:
            raise IOError("Cannot read: USBSerialPort is not open.")
        try:
            data = self.ep_in.read(size, timeout=timeout)
            self.logger.debug(f"Read {len(data)} bytes from endpoint 0x81")
            # Print hex format for debugging
            self.logger.debug(" ".join(f"{b:02X}" for b in data))
            return bytes(data)
        except usb.core.USBError as e:
            # If it's a timeout, you might prefer returning an empty bytes object
            self.logger.debug(f"Read USBError: {e}")
            if e.errno == 110:  # 110 is typically a timeout on many systems
                return b""
            raise


# ======= ax630tool =======


class AXDLGlobData:
    MAGIC_NUMBER = 0x5C6D8E9F


class AXDLTool:

    def checksum16(self, data: bytes) -> int:
        """Compute 16-bit checksum over the given data bytes."""
        total = 0
        idx = 0
        length = len(data)
        while idx < length - 1:
            val = data[idx] | (data[idx + 1] << 8)
            total += val
            total &= 0xFFFFFFFF
            idx += 2
        if length % 2 == 1:
            total += data[-1]
            total &= 0xFFFFFFFF
        while (total >> 16) != 0:
            total = (total & 0xFFFF) + (total >> 16)
        return (~total) & 0xFFFF

    def build_packet(self, cmd: int, payload: bytes = b"") -> bytes:
        """Build a packet: MAGIC(4) + LENGTH(2) + CMD(2) + PAYLOAD + CRC(2)."""
        length_bytes = struct.pack("<H", len(payload))
        cmd_bytes = struct.pack("<H", cmd)
        to_cksum = length_bytes + cmd_bytes + payload
        csum = self.checksum16(to_cksum)
        csum_bytes = struct.pack("<H", csum)
        return struct.pack("<I", AXDLGlobData.MAGIC_NUMBER) + to_cksum + csum_bytes

    def parse_packet(self, resp: bytes):
        """Parse the packet from raw bytes -> (cmd, payload) or None if invalid."""
        if len(resp) < 8:
            return None
        magic = struct.unpack_from("<I", resp, 0)[0]
        if magic != AXDLGlobData.MAGIC_NUMBER:
            return None
        length_val = struct.unpack_from("<H", resp, 4)[0]
        cmd_val = struct.unpack_from("<H", resp, 6)[0]
        total_len = 4 + 2 + 2 + length_val + 2
        if len(resp) < total_len:
            return None
        payload = resp[8 : 8 + length_val]
        csum_pkt = struct.unpack_from("<H", resp, 8 + length_val)[0]
        to_cksum = resp[4 : 4 + 2 + 2 + length_val]
        if self.checksum16(to_cksum) != csum_pkt:
            return None
        return (cmd_val, payload)

    tmp_axp_path = None

    def __del__(self):
        if self.tmp_axp_path != None:
            self.tmp_axp_path.cleanup()
            self.tmp_axp_path = None

    def extract_axp(self, axp_path: str, logger: logging.Logger):
        """
        Extract all files from an AXP (zip) to temp, returning (xml_content, extracted_files).
        """
        if self.tmp_axp_path == None:
            self.tmp_axp_path = tempfile.TemporaryDirectory()
        if not os.path.isfile(axp_path):
            logger.error(f"AXP file not found: {axp_path}")
            sys.exit(1)
        with zipfile.ZipFile(axp_path, "r") as zip_ref:
            for file_info in zip_ref.infolist():
                try:
                    zip_ref.extract(file_info, self.tmp_axp_path.name)
                except Exception as e:
                    pass
        xml_content = None
        extracted_file_list = glob.glob(os.path.join(self.tmp_axp_path.name, "*"))
        extracted_files = {}
        if len(extracted_file_list) != 0:
            for file_path in extracted_file_list:
                file_name = os.path.basename(file_path)
                extracted_files[file_name] = file_path
                if file_name.lower().endswith(".xml"):
                    with open(file_path, "r", encoding="utf-8") as xml_file:
                        xml_content = xml_file.read()

        if not xml_content:
            logger.error("No XML found in AXP.")
            sys.exit(1)

        return xml_content, extracted_files

    def parse_config_xml(self, xml_str: str, logger: logging.Logger):
        """
        Parse the XML to extract:
        - FDL1 file name & base
        - FDL2 file name & base
        - The 'unit' from <Partitions unit="...">
        - The list of partitions: (id, size, gap)
        - The full <ImgList> in order (for subsequent downloading)
        Returns a dict with e.g.:
        {
            'fdl1': {'file': 'fdl1.bin', 'base': 0x03000000},
            'fdl2': {'file': 'fdl2.bin', 'base': 0x5C000000},
            'unit': 2,
            'partitions': [
                {'id': 'spl', 'size': 768, 'gap': 0},
                ...
            ],
            'imglist': [
                {
                    'id': 'FDL1',
                    'file': 'fdl1.bin',
                    'base': 0x3000000,
                    'block_id': None or 'somepart',
                    'select': True/False,
                    'flag': 3,
                    'type': 'FDL1'
                },
                ...
            ]
        }
        """
        root = ET.fromstring(xml_str)  # <Config>
        project = root.find("Project")
        if project is None:
            logger.error("No <Project> in XML.")
            sys.exit(1)

        # Partitions
        partitions_elem = project.find("Partitions")
        if partitions_elem is None:
            logger.error("No <Partitions> in XML.")
            sys.exit(1)
        # read 'unit' from <Partitions unit="...">
        str_unit = partitions_elem.get("unit", "2")
        unit = int(str_unit, 0)  # parse as decimal or hex

        # gather partition info
        partition_list = []
        for pe in partitions_elem.findall("Partition"):
            pid = pe.get("id", "")
            psize = int(pe.get("size", "0"), 0)
            pgap = int(pe.get("gap", "0"), 0)
            partition_list.append({"id": pid, "size": psize, "gap": pgap})

        # parse <ImgList>
        img_list_elem = project.find("ImgList")
        if img_list_elem is None:
            logger.error("No <ImgList> in XML.")
            sys.exit(1)

        # placeholders
        fdl1_info = {"file": None, "base": None}
        fdl2_info = {"file": None, "base": None}
        eip_info = {"file": None, "base": None}
        full_img_list = []

        for img_elem in img_list_elem.findall("Img"):
            id_node = img_elem.find("ID")
            file_node = img_elem.find("File")
            block_elem = img_elem.find("Block")

            if id_node is None:
                continue
            img_id = id_node.text.strip() if id_node.text else ""
            fname = (
                file_node.text.strip()
                if (file_node is not None and file_node.text)
                else ""
            )
            flag_str = img_elem.get("flag", "0")
            select_str = img_elem.get("select", "0")
            # parse base from <Block><Base>0x3000000</Base></Block> if present
            base_addr = 0
            block_id = None
            if block_elem is not None:
                base_text = block_elem.findtext("Base", "0")
                block_id = block_elem.get("id", None)
                if base_text.startswith("0x") or base_text.startswith("0X"):
                    base_addr = int(base_text, 16)
                else:
                    base_addr = int(base_text)

            # catch EIP / FDL1 / FDL2 specifically
            if img_id == "FDL1":
                fdl1_info["file"] = fname
                fdl1_info["base"] = base_addr
            elif img_id == "FDL2":
                fdl2_info["file"] = fname
                fdl2_info["base"] = base_addr
            elif img_id == "EIP":
                eip_info["file"] = fname
                eip_info["base"] = base_addr
            else:
                # store
                one_img = {
                    "id": img_id,
                    "file": fname,
                    "base": base_addr,
                    "block_id": block_id,
                    "flag": int(flag_str),
                    "select": (select_str == "1"),
                    "type": img_elem.findtext("Type", "").strip(),
                }
                full_img_list.append(one_img)

        if not fdl1_info["file"] or fdl1_info["base"] is None:
            logger.error("FDL1 (file/base) not properly found in XML.")
            sys.exit(1)
        if not fdl2_info["file"] or fdl2_info["base"] is None:
            logger.error("FDL2 (file/base) not properly found in XML.")
            sys.exit(1)

        return {
            "fdl1": fdl1_info,
            "fdl2": fdl2_info,
            "eip": eip_info,
            "unit": unit,
            "partitions": partition_list,
            "imglist": full_img_list,
        }

    def handshake(self, port, logger, stage_name="ROM CODE") -> bool:
        """Repeatedly send 0x3C until receiving BSL_REP_VER."""
        max_tries = 10
        for attempt in range(max_tries):
            port.write(bytes([CMD_HANDSHAKE_BYTE] * 3))
            time.sleep(0.1)
            resp = port.read(512, timeout=2000)
            if not resp:
                logger.debug(f"{stage_name} handshake attempt {attempt+1}: no data.")
                continue
            parsed = self.parse_packet(resp)
            if parsed:
                cmd, payload = parsed
                if cmd == BSL_REP_VER:
                    logger.info(
                        f'{stage_name} handshake success. ({payload.decode("utf-8", errors="ignore")})'
                    )
                    return resp.decode("utf-8", errors="ignore")
        return ""

    def cmd_connect(self, port, logger):
        """Send BSL_CMD_CONNECT -> expect ACK."""
        pkt = self.build_packet(BSL_CMD_CONNECT)
        port.write(pkt)
        resp = port.read(512)
        parsed = self.parse_packet(resp)
        if parsed and parsed[0] == BSL_REP_ACK:
            logger.info("BSL_CMD_CONNECT -> ACK")
            return True
        logger.error("BSL_CMD_CONNECT -> no ACK")
        return False

    def download_fdl(
        self, port, logger, fdl_path: str, base_addr: int, stage_name="FDL?"
    ) -> bool:
        """
        Download an FDL via (START_DATA -> chunked -> ENDED_DATA -> EXEC_DATA).
        Uses the older code example.
        """
        if not os.path.isfile(fdl_path):
            logger.error(f"File not found: {fdl_path}")
            return False
        size = os.path.getsize(fdl_path)
        logger.info(
            f"Downloading {stage_name} from {Path(fdl_path).name}, size={size} bytes, base=0x{base_addr:X}"
        )

        # Send BSL_CMD_START_DATA
        if stage_name == "FDL1":
            start_payload = struct.pack("<II", base_addr, size)
        elif stage_name == "FDL2":
            start_payload = struct.pack("<QQ", base_addr, size)
        else:
            logger.error(f"Unknown stage name for FDL download: {stage_name}")
        pkt_start = self.build_packet(BSL_CMD_START_DATA, start_payload)
        port.write(pkt_start)
        resp = port.read(512)
        parsed = self.parse_packet(resp)
        if not (parsed and parsed[0] == BSL_REP_ACK):
            logger.error(f"No ACK after START_DATA for {stage_name}.")
            return False

        chunk_size = 1000
        pbar = tqdm(total=size, unit="B", unit_scale=True, desc=f"{stage_name}")

        with open(fdl_path, "rb") as f:
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                # BSL_CMD_MIDST_DATA
                # We'll typically set Enable=0 => no partial-checksum, and CheckSum=0 => filler.
                chunk_len = len(chunk)
                mids_payload = struct.pack("<III", chunk_len, 0, 0)
                pkt_midst = self.build_packet(BSL_CMD_MIDST_DATA, mids_payload)
                port.write(pkt_midst)
                resp = port.read(512, timeout=2000)
                parsed = self.parse_packet(resp)
                if not (parsed and parsed[0] == BSL_REP_ACK):
                    logger.error(f"No ACK after MIDST_DATA header for {stage_name}.")
                    return False

                # send the chunk
                port.write(chunk)
                resp = port.read(512, timeout=30000)
                parsed = self.parse_packet(resp)
                if not (parsed and parsed[0] == BSL_REP_ACK):
                    logger.error(f"No ACK after data chunk for {stage_name}.")
                    return False

                pbar.update(chunk_len)

        pbar.close()

        # BSL_CMD_ENDED_DATA
        pkt_end = self.build_packet(BSL_CMD_ENDED_DATA)
        port.write(pkt_end)
        resp = port.read(512)
        parsed = self.parse_packet(resp)
        if not (parsed and parsed[0] == BSL_REP_ACK):
            logger.error(f"No ACK after ENDED_DATA for {stage_name}, retrying.")
            return False

        logger.info(f"{stage_name} download complete.")

        # EXEC_DATA => run this FDL
        pkt_exec = self.build_packet(BSL_CMD_EXEC_DATA)
        port.write(pkt_exec)
        resp = port.read(512, timeout=3000)
        parsed = self.parse_packet(resp)
        if not (parsed and parsed[0] == BSL_REP_ACK):
            logger.error(f"EXEC_DATA no ACK from {stage_name}.")
            return False

        logger.info(f"{stage_name} is now running.")
        return True

    def str_to_unicode_le(self, s: str, max_chars=36):
        """
        Encode a python string as little-endian UTF-16, padded/truncated to max_chars,
        returning the raw bytes. The doc requires wchar_t[36].
        """
        # Truncate if needed
        s = s[:max_chars]
        encoded = s.encode("utf-16-le")  # 2 bytes per char
        # We need exactly max_chars * 2 bytes, pad with zeros if short
        needed = max_chars * 2
        if len(encoded) < needed:
            encoded += b"\x00" * (needed - len(encoded))
        return encoded

    def repartition(self, port, logger, unit: int, partitions: list):
        """
        Sends BSL_CMD_REPARTITION(0x0B) with PARTITION_HEAD + PARTITION_BODY[].
        struct PARTITION_HEAD {
        uint32 magic=0x3A726170; // "par:"
        uint8  version=1;
        uint8  unit;
        uint16 count; // number of PARTITION_BODY entries
        }
        struct PARTITION_BODY {
        wchar_t id[36]; // partition name in UTF-16-LE
        int64   size;   // final size in "unit" multiples
        int64   gap;    // typically 0
        }
        """
        MAGIC = 0x3A726170
        UNIT_SIZE_TABLE = {0: 1048576, 1: 524288, 2: 1024, 3: 1}
        version = 1
        count = len(partitions)

        # Print head and each parition info
        logger.debug(
            f"PARTITION_HEAD: MAGIC=0x{MAGIC:08X}, version={version}, unit={unit}, count={count}"
        )
        for p in partitions:
            logger.debug(
                f"PARTITION_BODY: id={p['id']}, size={p['size']}, gap={p['gap']}"
            )

        # Build PARTITION_HEAD
        part_head = struct.pack("<IBBH", MAGIC, version, unit, count)

        # Build array of PARTITION_BODY
        body_bytes = b""
        for p in partitions:
            name_bytes = self.str_to_unicode_le(p["id"])
            p_size = p["size"]
            p_gap = p["gap"]
            body_bytes += name_bytes
            body_bytes += struct.pack("<qq", p_size, p_gap)

        payload = part_head + body_bytes
        pkt = self.build_packet(BSL_CMD_REPARTITION, payload)
        port.write(pkt)
        resp = port.read(512, timeout=3000)
        parsed = self.parse_packet(resp)
        if not parsed or parsed[0] != BSL_REP_ACK:
            logger.error("BSL_CMD_REPARTITION -> no ACK.")
            return False

        logger.info(f"Repartition done. (#Partitions: {count}, unit={unit})")
        return True

    def start_data_cmd(self, port, logger, part_id: str, file_size: int):
        """
        BSL_CMD_START_DATA(0x01)
        Payload:
        - Id(72 bytes, unicode)
        - Size(8 bytes)
        - Reserved(8 bytes=0)
        """
        name_bytes = self.str_to_unicode_le(
            part_id, max_chars=36
        )  # 36 wide-chars => 72 bytes
        payload = (
            name_bytes
            + struct.pack("<Q", file_size)  # 8 bytes
            + struct.pack("<Q", 0)  # 8 bytes reserved
        )
        pkt = self.build_packet(BSL_CMD_START_DATA, payload)
        port.write(pkt)
        resp = port.read(512, timeout=2000)
        parsed = self.parse_packet(resp)
        if not parsed or parsed[0] != BSL_REP_ACK:
            logger.error(f"No ACK after START_DATA for partition '{part_id}'.")
            return False
        return True

    def send_data_chunks(self, port, logger, fpath: str, part_name: str):
        """
        Repeatedly send BSL_CMD_MIDST_DATA(0x02) -> {data}, until file is done.
        """
        if not os.path.isfile(fpath):
            logger.error(f"File not found: {fpath}")
            return False

        size = os.path.getsize(fpath)
        chunk_size = 0xB000
        pbar = tqdm(total=size, unit="B", unit_scale=True, desc=part_name)

        with open(fpath, "rb") as f:
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                length = len(chunk)

                # BSL_CMD_MIDST_DATA(0x02) payload => Size(4) + Enable(4) + CheckSum(4)
                # We'll do "Enable=0" => no sub-chunk checksumming, then "CheckSum=0".
                mids_payload = struct.pack("<III", length, 0, 0)
                pkt_midst = self.build_packet(BSL_CMD_MIDST_DATA, mids_payload)
                port.write(pkt_midst)
                resp = port.read(512, timeout=5000)
                parsed = self.parse_packet(resp)
                if not (parsed and parsed[0] == BSL_REP_ACK):
                    logger.error(
                        f"No ACK after MIDST_DATA header for partition '{part_name}'."
                    )
                    return False

                # Now send the actual chunk
                port.write(chunk)
                resp = port.read(512, timeout=120000)
                parsed = self.parse_packet(resp)
                if not (parsed and parsed[0] == BSL_REP_ACK):
                    logger.error(
                        f"No ACK after data chunk for partition '{part_name}'."
                    )
                    return False

                pbar.update(length)

        pbar.close()
        return True

    def ended_data_cmd(self, port, logger, part_id: str):
        """
        BSL_CMD_ENDED_DATA(0x03) => finalize.
        """
        pkt = self.build_packet(BSL_CMD_ENDED_DATA)
        port.write(pkt)
        resp = port.read(512, timeout=120000)
        parsed = self.parse_packet(resp)
        if not (parsed and parsed[0] == BSL_REP_ACK):
            logger.error(f"No ACK after ENDED_DATA for '{part_id}'.")
            return False
        else:
            return True

    def erase_partition(self, port, logger, part_id: str):
        """
        Example of using BSL_CMD_ERASE_FLASH(0x0A) to erase a partition by name.
        According to the doc:
        Payload:
            - Flag(8) = 0 => partial erase
            - Id(72) = partition name in unicode
            - Size(8) => portion to erase; 0 => entire partition
        """
        logger.info(f"Erasing partition '{part_id}' ...")
        name_bytes = self.str_to_unicode_le(part_id, 36)
        payload = struct.pack("<Q", 0) + name_bytes + struct.pack("<Q", 0)
        pkt = self.build_packet(BSL_CMD_ERASE_FLASH, payload)
        port.write(pkt)
        resp = port.read(512, timeout=120000)
        parsed = self.parse_packet(resp)
        if not parsed or parsed[0] != BSL_REP_ACK:
            logger.error(f"No ACK after erase partition '{part_id}'.")
            return False
        logger.info(f"Partition '{part_id}' erased.")
        return True

    def download_images(self, port, logger, images: list, extracted_files: dict):
        """
        Iterate over the parsed <ImgList> in the exact order.  For each:
        - If select="0", skip
        - If type="ERASEFLASH", do BSL_CMD_ERASE_FLASH(0x0A)
        - Else do (START_DATA -> chunk -> ENDED_DATA) with the partition "id"
            from <Block id="...">, and file content from <File>...
        """
        for img in images:
            if not img["select"]:
                logger.info(f"Skipping '{img['id']}' (select=0).")
                continue

            img_id = img["id"]
            fpath = extracted_files.get(img["file"], None) if img["file"] else None
            part_id = img["block_id"] if img["block_id"] else img_id  # fallback
            typ = img["type"].upper()

            # If it's an erase request
            if typ == "ERASEFLASH":
                self.erase_partition(port, logger, part_id)
                continue

            # If there's no actual file (like "INIT"?), skip
            if not fpath or not os.path.isfile(fpath):
                logger.debug(f"Image '{img_id}' has no valid file to burn. Skipping.")
                continue

            file_size = os.path.getsize(fpath)
            logger.info(
                f"Burning '{img_id}' => partition '{part_id}', file='{Path(fpath).name}', size={file_size} bytes."
            )

            # 1) BSL_CMD_START_DATA
            if not self.start_data_cmd(port, logger, part_id, file_size):
                return False

            # 2) BSL_CMD_MIDST_DATA (in chunks)
            if not self.send_data_chunks(port, logger, fpath, img_id):
                return False

            # 3) BSL_CMD_ENDED_DATA
            if not self.ended_data_cmd(port, logger, img_id):
                return False

        return True


def main():
    parser = argparse.ArgumentParser(
        description="Axera chip USB downloader tool.",
    )
    parser.add_argument("--axp", required=True, help="Path to the AXP package (.axp).")
    parser.add_argument("--reset", action="store_true", help="Reset after finish.")

    parser.add_argument(
        "--vid",
        type=lambda x: int(x, 16),
        default=0x32C9,
        help="USB Vendor ID in hex (e.g. 0x32c9).",
    )
    parser.add_argument(
        "--pid",
        type=lambda x: int(x, 16),
        default=0x1000,
        help="USB Product ID in hex (e.g. 0x1000).",
    )

    parser.add_argument("--debug", action="store_true", help="Enable debug logging.")
    args = parser.parse_args()

    log_level = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(
        level=log_level, format="%(asctime)s [%(levelname)s] %(message)s"
    )
    logger = logging.getLogger("ax_usb_serial_dl")
    AXDL = AXDLTool()
    # 1) Extract AXP & parse config
    logger.info(f"Extracting AXP: {Path(args.axp).name}")
    xml_content, extracted_files = AXDL.extract_axp(args.axp, logger)
    cfg = AXDL.parse_config_xml(xml_content, logger)
    fdl1_path = extracted_files.get(cfg["fdl1"]["file"], None)
    fdl2_path = extracted_files.get(cfg["fdl2"]["file"], None)
    if not fdl1_path or not os.path.isfile(fdl1_path):
        logger.error(
            f"FDL1 file '{cfg['fdl1']['file']}' not found among extracted files."
        )
        sys.exit(1)
    if not fdl2_path or not os.path.isfile(fdl2_path):
        logger.error(
            f"FDL2 file '{cfg['fdl2']['file']}' not found among extracted files."
        )
        sys.exit(1)

    # 2) Open the USB port
    port = USBSerialPort(args.vid, args.pid, logger=logger)
    port.open()

    # 3) Handshake with ROM CODE
    rom_resp = AXDL.handshake(port, logger, stage_name="ROM CODE")
    if len(rom_resp) == 0:
        logger.error("ROM CODE handshake failed.")
        port.close()
        sys.exit(1)
    if not AXDL.cmd_connect(port, logger):
        port.close()
        sys.exit(1)

    # 3.1) EIP
    # TODO: This part is not tested.
    if "secureboot" in rom_resp:
        logger.info("Secure boot detected...")
        if not AXDL.download_fdl(
            port, logger, fdl1_path, cfg["eip"]["base"], stage_name="EIP"
        ):
            port.close()
            sys.exit(1)

    # 4) Download FDL1
    if not AXDL.download_fdl(
        port, logger, fdl1_path, cfg["fdl1"]["base"], stage_name="FDL1"
    ):
        port.close()
        sys.exit(1)

    # 5) Handshake with FDL1
    if not AXDL.handshake(port, logger, stage_name="FDL1"):
        logger.error("FDL1 handshake failed.")
        port.close()
        sys.exit(1)
    if not AXDL.cmd_connect(port, logger):
        port.close()
        sys.exit(1)

    # 6) Download FDL2
    if not AXDL.download_fdl(
        port, logger, fdl2_path, cfg["fdl2"]["base"], stage_name="FDL2"
    ):
        port.close()
        sys.exit(1)

    logger.info("Preparing to repartition & burn images...")

    # 7) Repartition (BSL_CMD_REPARTITION)
    if not AXDL.repartition(port, logger, cfg["unit"], cfg["partitions"]):
        logger.error("Repartition failed.")
        port.close()
        sys.exit(1)

    # 8) Burn images in <ImgList> order
    if not AXDL.download_images(port, logger, cfg["imglist"], extracted_files):
        logger.error("Failed during image downloads.")
        port.close()
        sys.exit(1)

    logger.info(
        "All images downloaded successfully. Optionally reset device with BSL_CMD_RESET..."
    )

    # 9) (Optional) Send BSL_CMD_RESET(0x05):
    if args.reset:
        payload = struct.pack("<I", 0)
        pkt_reset = AXDL.build_packet(BSL_CMD_RESET, payload)
        port.write(pkt_reset)
        resp = port.read(512, timeout=10000)
        parsed = AXDL.parse_packet(resp)
        if parsed and parsed[0] == BSL_REP_ACK:
            logger.info("Device has ACKed reset; it should reboot into normal mode.")
        else:
            logger.warning("No ACK after reset command.")

    # close port
    port.close()
    logger.info("All operations completed. Exiting.")


if __name__ == "__main__":
    main()
