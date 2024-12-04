export LCD_FRAMEBUFFER=`cat /proc/fb | grep ili9342c | awk '{print "/dev/fb"$1}'`
export HDMI_FRAMEBUFFER=`cat /proc/fb | grep stmdrmfb | awk '{print "/dev/fb"$1}'`
