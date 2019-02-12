#include <Arrays\ArrayChar.mqh>

class CCharBuffer:public CArrayChar{
public:
   bool CutHead(char t,uchar &res[]){
      int pos=-1;
      for(int i=0;i<this.m_data_total;i++){
         if(this.m_data[i]==t){
            pos=i;
            break;
         }
      }
      if(pos==-1)
         return false;
      ArrayResize(res,pos+1);
      for(int i=0;i<=pos;i++){
         res[i]=m_data[i];
      }
      DeleteRange(0,pos);
      return true;
   }
};

class SocketClient{
protected:
   int connectsocket;
   string host;
   uint port;
   CCharBuffer recvbuff;
public:
   bool isNewConnect;
   void SocketClient(string host,uint port){
      connectsocket=0;
      isNewConnect=false;
      this.host=host;
      this.port=port;
   }
   void TickCheck(){
      if(connectsocket==0)
         return;
      while(true){
         int count=SocketIsReadable(connectsocket);
         uchar redbuf[];
         bool secced=false;
         if(count>0){
            count=SocketRead(connectsocket,redbuf,count,10);
            if(count>0){
               secced=true;
               ArrayResize(redbuf,count);
               recvbuff.AddArray(redbuf);
            }
         }
         if(secced==false){
            break;
         }
      }
      while(true){
         char buf[];
         if(recvbuff.CutHead(0,buf)){
            onRecvMessage(buf);
         }else{
            break;
         }
      }
   }
   void SendString(string data){
      char req[];
      int  len=StringToCharArray(data,req);
      
      MakeSureConnect();
      if(SocketIsWritable(connectsocket)){
         if(!SocketSend(connectsocket,req,ArraySize(req))){
            SocketClose(connectsocket);
            connectsocket=0;
         }
      }
      else{
         SocketClose(connectsocket);
         connectsocket=0;
      }
   }
   virtual void onRecvMessage(uchar &buf[]){
   }
protected:
   void MakeSureConnect(){
      if(connectsocket!=0){
         return;
      }
      connectsocket=SocketCreate();
      if(!SocketConnect(connectsocket,host,port,5000)){
         Print("connect error #",GetLastError());
      }
      else{
         isNewConnect=true;
      }
   }
};

