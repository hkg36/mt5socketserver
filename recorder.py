import frame
import asyncore
import pymongo

dbclient=pymongo.MongoClient("mongodb://192.168.31.17:27017/")
db=dbclient["mt5record"]

class RecordHandler(frame.MT5Handler):
    def onRecvMessage(self,buf):
        data=buf.decode("utf8").strip("\x00\n\r")
        tagpos=data.find("$")
        tag=data[:tagpos].replace(",","_")
        bars=data[tagpos+1:].split(";")
        ops=[]
        for bar in bars:
            if bar:
                b2=bar.split(",")
                ops.append(pymongo.UpdateOne({"_id":int(b2[0])},
                                             {"$set":{"o":float(b2[1]),"c":float(b2[2]),"h":float(b2[3]),"l":float(b2[4])}},upsert=True))
        db[tag].bulk_write(ops)

server = frame.MT5Server('0.0.0.0', 8080,RecordHandler)
asyncore.loop()