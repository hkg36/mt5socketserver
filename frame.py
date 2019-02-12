import asyncore
import socket
import datetime
import blist

class MT5Handler(asyncore.dispatcher_with_send):
    def __init__(self,sock=None, map=None):
        super(MT5Handler,self).__init__(sock,map)
        self.recvbuf=bytearray()
        self.bars={}
    def handle_read(self):
        data = self.recv(8192)
        self.recvbuf.extend(data)
        while 1:
            pos=None
            for i in range(len(self.recvbuf)):
                if self.recvbuf[i]==0:
                    pos=i
                    break
            if pos is None:
                break
            else:
                data=self.recvbuf[:pos+1]
                del self.recvbuf[:pos+1]
                self.onRecvMessage(data)

    def onRecvMessage(self,buf):
        data=buf.decode("utf8").strip("\x00\n\r")
        tagpos=data.find("$")
        tag=data[:tagpos]
        bars=data[tagpos+1:].split(";")
        if tag in self.bars:
            savebars=self.bars[tag]
        else:
            savebars=blist.sorteddict()
            self.bars[tag]=savebars
        for bar in bars:
            if bar:
                b2=bar.split(",")
                cad={"time":int(b2[0]),
                     "open":float(b2[1]),
                     "close":float(b2[2]),
                     "high":float(b2[3]),
                     "low":float(b2[4])}
                savebars[cad["time"]]=cad
        self.send("ok {}\x00".format(datetime.datetime.now()).encode("utf8"))

class MT5Server(asyncore.dispatcher):

    def __init__(self, host, port,handler=MT5Handler):
        asyncore.dispatcher.__init__(self)
        self.handler=handler
        self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
        self.set_reuse_addr()
        self.bind((host, port))
        self.listen(5)
    def handle_accept(self):
        pair = self.accept()
        if pair is not None:
            sock, addr = pair
            print('Incoming connection from %s' % repr(addr))
            handler = self.handler(sock)
if __name__ == "__main__":
    server = MT5Server('0.0.0.0', 8080)
    asyncore.loop()