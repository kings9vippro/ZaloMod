# Kiểm tra offset thực từ bản Zalo mà bạn cung cấp

Công cụ `inspect_zalo_offsets.py` đọc Mach-O ARM64 bên trong IPA đã được giải mã, không cần jailbreak để phân tích **tĩnh**.

Lệnh:

```bash
python3 PHKIndependent/Tools/inspect_zalo_offsets.py "Zalo-PHK-1.2-Unsigned.ipa" --output reports/zalo-1.2-macho.json
```

Các trường kết quả: Mach-O SHA-256, UUID build, `CFBundleVersion`, `LC_LOAD_DYLIB`, trạng thái mã hóa, tên lớp/phương thức Objective-C còn lưu trong các section `__objc_classname` và `__objc_methname`, và các địa chỉ symbol **không có ASLR** nếu bảng symbol có thông tin.

**Không thể gọi hàm chỉ từ offset của chuỗi tên lớp/phương thức.** Chỉ những symbol có địa chỉ thực, ABI được kiểm tra và cùng UUID build mới có cơ sở để thiết kế adapter; các thao tác mạng vẫn cần điểm tích hợp hợp lệ và kiểm thử trên thiết bị.

Không in cookie, token hoặc nội dung hội thoại. Lệnh chỉ đọc, không patch mã gốc.
