import os
import sys
import rsa
import ctypes
import traceback
import struct
import hashlib

def print_usage():
    print('\nbuild_spl.py -i <spl_file> -pub <public_key_file(*.pem)> -prv <private_key_file(*.pem)> -o <out_file>')
    print('  -i   :  input file path')
    print('  -pub :  input rsa public key file (*.pem) path')
    print('  -prv :  input rsa private key file (*.pem) path')
    print('  -o   :  output new signed file')
    print('  -cap :  input capability of header field\n')

'''
image header struct:
struct image_header {
    uint32_t                    check_sum;         /* header check sum */
    uint32_t                    capability;
    uint8_t                     magic[6];
    uint32_t                    image_size;
    uint8_t                     hash_digest[32];
    uint32_t                    key_n_header;
    uint8_t                     rsa_key_n[384];
    uint32_t                    key_e_header;
    uint8_t                     rsa_key_e[4];
    uint32_t                    sig_header;
    uint8_t                     signature[384];
};
'''

header_size = 1024

class image_header(ctypes.Structure):
    _pack_ = 4
    _fields_ = [
        ("check_sum", ctypes.c_uint),
        ("capability", ctypes.c_uint),
        ("magic", ctypes.c_uint8 * 6),
        ("image_size", ctypes.c_uint),
        ("hash_digest", ctypes.c_uint8 * 32),
        ("key_n_header", ctypes.c_uint),  # 0x02000800 //0x00, 0x08, 0x00, 0x02
        ("rsa_key_n", ctypes.c_uint8 * 384), # 4 x 96
        ("key_e_header", ctypes.c_uint),  # 0x02010020 //0x20, 0x00, 0x01, 0x02
        ("rsa_key_e", ctypes.c_uint8 * 4),
        ("sig_header", ctypes.c_uint),    # 0x01000800 //0x00, 0x08, 0x00, 0x01
        ("signature", ctypes.c_uint8 * 384), # 4 x 96
        ("reserved", ctypes.c_uint8 * 188) # 1024 - 836
    ]

def copy_data_by_bytes(src, dst, length, dst_offset= 0, revers=False):
    if sys.version > '3':
        for i in range(length):
            if revers:
                dst[dst_offset + i] = ctypes.c_uint8(src[length - i - 1])
            else:
                dst[dst_offset + i] = ctypes.c_uint8(src[i])
    else:
        for i in range(length):
            if revers:
                dst[dst_offset + i] = ctypes.c_uint8(ord(src[length - i - 1]))
            else:
                dst[dst_offset + i] = ctypes.c_uint8(ord(src[i]))

def to_bytes(n, length, byteorder='big'):
    if sys.version > '3':
        return n.to_bytes(length, byteorder=byteorder, signed=False)
    else:
        if byteorder == 'big':
            data = b''
            for i in reversed(range(length)):
                d = (n >> i * 8) & 0xff
                data += struct.pack("B", d)
            return data
        else:
            data = b''
            for i in range(length):
                d = (n >> i * 8) & 0xff
                data += struct.pack("B", d)
            return data

def make_image(input_file, pub_file, prv_file, output_file, capability, key_bit):
    # load pub and private key file
    try:
        with open(pub_file, 'rb') as f:
            pub_key = rsa.PublicKey.load_pkcs1(f.read())

        with open(prv_file, 'rb') as f:
            prv_key = rsa.PrivateKey.load_pkcs1(f.read())
    except:
        print('[error] load public or private key file failed\n')
        print(sys.exc_info())
        print(traceback.format_exc())
        return False

    # load input file data
    input_size = os.path.getsize(input_file)
    try:
        with open(input_file, 'rb') as f:
            input_data = f.read()
    except:
        print('[error] load input file failed\n')
        print(sys.exc_info())
        print(traceback.format_exc())
        return False

    image_data = input_data

    header = image_header()
    p = ctypes.cast(ctypes.pointer(header), ctypes.POINTER(ctypes.c_uint8 * header_size))
    ctypes.memset(p, 0, header_size)
    # capability
    header.capability = capability
    # magic, AXERA!
    header.magic[0] = 0x41
    header.magic[1] = 0x58
    header.magic[2] = 0x45
    header.magic[3] = 0x52
    header.magic[4] = 0x41
    header.magic[5] = 0x21
    # image size
    header.image_size = header_size + input_size

    # compute image data SHA256
    id = hashlib.sha256(image_data).digest()
    copy_data_by_bytes(id, header.hash_digest, 32, 0)
    # rsa key
    # key_bit = 2048 or 3072
    if key_bit == 2048:
        key_byte = 256
        header.key_n_header = 0x02000800
    elif key_bit == 3072:
        key_byte = 384
        header.key_n_header = 0x02000C00
    else:
        print('key size not valid')
        exit(-1)

    header.key_e_header = 0x02010020
    # rsa_key_n
    pub_n = to_bytes(pub_key.n, key_byte, byteorder='little')
    copy_data_by_bytes(pub_n, header.rsa_key_n, key_byte)
    # rsa_key_e
    pub_e = to_bytes(pub_key.e, 4, byteorder='little')
    copy_data_by_bytes(pub_e, header.rsa_key_e, 4)
    # sign data
    # key_bit = 2048 or 3072
    if key_bit == 2048:
        header.sig_header = 0x01000800
    else:
        header.sig_header = 0x01000C00

    signature = rsa.sign(image_data, prv_key, 'SHA-256')
    copy_data_by_bytes(signature, header.signature, key_byte, 0, True)

    # verify test
    try:
        ret = rsa.verify(image_data, signature, pub_key)
    except e:
        print('[error] verify failed\n')
        print(sys.exc_info())
        print(traceback.format_exc())
        exit(-1)
    # calc header check sum
    header_data = (ctypes.c_uint8 * header_size)(0)
    p = ctypes.cast(ctypes.pointer(header), ctypes.POINTER(ctypes.c_uint8 * header_size))
    check_sum = ctypes.c_uint(0)
    for i in range(1, (header_size) // 4):
        data = p.contents[4 * i] + (p.contents[4 * i + 1] << 8) + (p.contents[4 * i + 2] << 16) + (p.contents[4 * i + 3] << 24)
        check_sum.value += ctypes.c_int(data).value
    header.check_sum = check_sum
    print("header check sum:")
    print(check_sum)

    output_data = (ctypes.c_uint8 * (header.image_size))(0)
    p = ctypes.cast(ctypes.pointer(header), ctypes.POINTER(ctypes.c_uint8 * header_size))
    for i in range(header_size):
        output_data[i] = p.contents[i]
    copy_data_by_bytes(image_data, output_data, input_size, header_size)

    # save data to out file
    try:
        with open(output_file, 'wb') as f:
            f.write(output_data)
    except:
        print('[error] create boot image file failed\n')
        print(sys.exc_info())
        print(traceback.format_exc())
        return False
    return True

if __name__ == '__main__':
    #gen_rsa_2048_keys()

    input_file = None
    pub_file = None
    prv_file = None
    out_file = None
    capability = None

    if len(sys.argv) < 13:
        print('[error] param is invalid\n')
        print_usage()
        exit(-1)

    for i in range(1, len(sys.argv)):
        if sys.argv[i] == '-i':
            input_file = sys.argv[i+1]
        elif sys.argv[i] == '-pub':
            pub_file = sys.argv[i+1]
        elif sys.argv[i] == '-prv':
            prv_file = sys.argv[i+1]
        elif sys.argv[i] == '-o':
            out_file = sys.argv[i + 1]
        elif sys.argv[i] == '-cap':
            capability = int(sys.argv[i + 1],16)
        elif sys.argv[i] == '-key_bit':
            key_bit = int(sys.argv[i + 1])

    if input_file is None or pub_file is None or prv_file is None or out_file is None or capability is None or key_bit is None:
        print('[error] param is invalid\n')
        print_usage()
        exit(-1)

    if (not os.path.exists(input_file)) or (not os.path.exists(pub_file)) or (not os.path.exists(prv_file)):
        print('[error] sign input file does not exist\n')
        exit(-1)

    ret = make_image(input_file, pub_file, prv_file, out_file, capability, key_bit)
    if ret:
        print('make image complete')
