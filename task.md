rebuild infrastructure for my whole systems

Termuux

- ~/.zshrc  main terminal
- ~/.bashrc debain terminal

computer

- ~/.bashrc windowns gitbash  ( ตอนนี้ยังไม่ได้โหลด ไฟล์จาก bashscripts)
- ~/.bashrc wsl ubuntu  

ทั้ง 4 ไฟล์จะเป็นกุญแจ สำหรับ โหลด local env และ สั่งโหลด ฟังก์ชั่นของ infrastructure ใน ~/bashscripts  ที่จะใช้ร่วมกันทั้ง 4 terminal  โดยผมจะกำหนด ให้แต่ละ termina' จะมี local env ของใครของมันที่  ~/.env  โดยทุกตัวแปรใน ~/bashscripts  จะเหมือนกันทุกประการผมจะใช้โฟร์นี้เป็น infrastructure config  สำหรับ system นี้

ภาระกิจสถาณการณ์ปัจจุบัน

ผมต้องการให้  combine ~/bascripts  บน termux   กับ ~/bashscripts บน wsl   ให้ทั้งคู่อัพเดท เป็น version เดัยวกัน ตอนนี้มีปันหา conflict อัพเดทแยกกัน ต้องเอามารวมกัน  ผมทำเองไม่ได้เพราะผมหาไม่เจอว่าต้องไหนอัพเดทไปแล้วบ้าง  ถ้าผมใช้ rsync  มันจะทำให้อันใดอันนึงถูกเขียนทัน ผมจึงอยากให้ช่วย รื้อระบบให้เป็นไปตามนี้ให้หน่อยครับ   ให้ทุก terminal  สามารถเชื่อต่อกันได้อย่างอิสระ ผ่านทาง SSH  มีข้อมูลทุกอย่างแล้วใน ~/bashscripts
