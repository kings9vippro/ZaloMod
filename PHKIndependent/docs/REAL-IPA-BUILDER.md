# PHKIndependent — cập nhật IPA Zalo từ bản lưu trữ

Công cụ `PHKIndependent/Tools/repack_zalo_ipa.py` **không tạo app demo**. Nó nhận bản lưu trữ `.app`/IPA Zalo người dùng đã có quyền chỉnh sửa, thay thư viện `PHKIndependent.dylib`, gắn lệnh `LC_LOAD_DYLIB` an toàn vào Mach-O và đóng gói IPA theo chuẩn `Payload/<App>.app`.

## Thao tác với bản Zalo PHK 1.4 đã có

```bash
python3 PHKIndependent/Tools/repack_zalo_ipa.py \
  --source "Zalo-PHK-1.4-Unsigned.ipa" \
  --dylib "PHKIndependent.dylib" \
  --output "Zalo-PHK-1.5-Unsigned.ipa" \
  --wallpaper "PHKMenuBridge/Resources/MenuWallpaper.jpg" \
  --admin-photo "PHKMenuBridge/Resources/AdminCar.jpg" \
  --require-independent
```

Chỉ dùng `--require-independent` **nếu IPA nguồn thật sự không còn `LC_LOAD_DYLIB` bắt buộc tới ZaloModVIP**. Nếu trình nạp còn phụ thuộc, công cụ báo lỗi thay vì tạo IPA có thể văng khi mở.

Có thể dùng bản `Lưu trữ.zip` gốc làm nguồn. Trường hợp đó, nếu `ZaloModVIP.dylib` vẫn là dependency bắt buộc, công cụ **giữ nguyên thư viện đó** để tránh lỗi dyld. Nó không tái tạo toàn bộ các hook ZaloModVIP.

## Những gì công cụ thực sự làm

- Kiểm tra Mach-O ARM64, mã hóa ứng dụng, thư viện bắt buộc và padding của load-command.
- Giữ bộ thực thi **Zalo gốc** và tài nguyên nằm trong archive nguồn; không thay thế bằng app SwiftUI demo.
- Chèn hoặc xác minh load command của PHKIndependent; không ghi đè mã máy bằng offset đoán mò.
- Đóng gói IPA chuẩn và kiểm tra CRC của từng thành phần.
- Giữ bundle identifier của nguồn, đổi tên hiển thị thành **Zalo PHK**.
- Chép ảnh nền và ảnh admin đã được cung cấp.
- Xuất báo cáo SHA-256, dependency còn lại và trạng thái **chưa ký**.

## Cần phân biệt

Đây là công cụ **tích hợp thư viện mới vào IPA**, không phải giải pháp tái tạo chức năng tin nhắn Zalo, zSticker AI hoặc bot. Các tính năng cần API/điểm tích hợp đã kiểm chứng; GitHub Actions build thành công không chứng minh chúng chạy trong ứng dụng. IPA phải được **ký lại hợp lệ** bằng chứng chỉ và provisioning phù hợp rồi kiểm thử trên iPhone trước khi sử dụng.

Không đăng IPA có mã nhị phân hoặc tài nguyên Zalo của bên thứ ba lên repository công khai khi chưa có quyền phân phối.
