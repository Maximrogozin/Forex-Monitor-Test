//+------------------------------------------------------------------+
//|                                                      FxMonic.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property version   "1.00"
#property strict

// Объявляем константы
#define INTERNET_DEFAULT_HTTP_PORT 80
#define INTERNET_SERVICE_HTTP 3

// Подключение библиотек
#import "wininet.dll"
int InternetAttemptConnect(int x);
int InternetOpenW(string sAgent, int lAccessType, string sProxyName, string sProxyBypass, int lFlags);
int InternetConnectW(int hInternet, string sServerName, int nServerPort, string sUsername, string sPassword, int nService, int nFlags, int nContext);
int HttpOpenRequestW(int hConnect, string sVerb, string sObjectName, string sVersion, string sReferrer, string& AcceptTypes[], int nFlags, int nContext);
int HttpSendRequestW(int hRequest, string sHeaders, int lHeadersLength, string sOptional, int lOptionalLength);
int InternetReadFile(int hFile, uchar &sBuffer[], int lNumBytesToRead, int &lNumberOfBytesRead);
int InternetCloseHandle(int hInet);
#import

// Параметры веб-сервера
input string ServerURL = "http://localhost:2000/api";
input int AccountNumber = 123456; // Номер торгового счета

// Параметр для хранения времени последнего запроса
datetime lastRequestTime = 0;

// Функция для отправки данных на сервер
void SendDataToServer(double balance, double equity, double free_margin)
  {
// Формируем JSON-строку вручную
   string data = "{";
   data += "\"account_number\":" + IntegerToString(AccountNumber) + ",";
   data += "\"balance\":" + DoubleToString(balance, 2) + ",";
   data += "\"equity\":" + DoubleToString(equity, 2) + ",";
   data += "\"free_margin\":" + DoubleToString(free_margin, 2);
   data += "}";

   string result;

// Открываем соединение с Интернетом
   int hInternet = InternetOpenW(" ", 0, " ", "", 0);
   if(hInternet != 0)
     {
      // Пытаемся установить соединение с сервером
      int hConnect = InternetConnectW(hInternet, "localhost", INTERNET_DEFAULT_HTTP_PORT, NULL, NULL, INTERNET_SERVICE_HTTP, 0, 0);
      if(hConnect != 0)
        {
         // Открываем запрос на сервер
         string acceptTypes[];
         int hRequest = HttpOpenRequestW(hConnect, "GET", ServerURL, "", "", acceptTypes, 0, 0);
         Print( hRequest,"ser");
         if(hRequest != 0)
           {
            // Отправляем данные с помощью HttpSendRequestW
            string header = "Content-Type: application/x-www-form-urlencoded";
            int response = HttpSendRequestW(hRequest, header, StringLen(header), data, StringLen(data));
            Print(GetLastError(),"res");
            if(response != 0)
              {
               int bytesRead;
               uchar buffer[1024];
               while(InternetReadFile(hRequest, buffer, ArraySize(buffer) - 1, bytesRead) && bytesRead > 0)
                 {
                  buffer[bytesRead] = '\0';
                  StringToCharArray(result, buffer, 0, bytesRead);
                 }
              }
            else
              {
               Print("Ошибка отправки запроса: ", GetLastError());
              }

            InternetCloseHandle(hRequest);
           }
         else
           {
            Print("Ошибка открытия запроса: ", GetLastError());
           }

         InternetCloseHandle(hConnect);
        }
      else
        {
         Print("Ошибка соединения с сервером: ", GetLastError());
        }

      InternetCloseHandle(hInternet);
     }
   else
     {
      Print("Ошибка открытия интернет-соединения: ", GetLastError());
     }

   if(StringLen(result) > 0)
     {
      Print("Данные успешно отправлены на сервер. Ответ сервера: ", result);
     }
   else
     {
      Print("Ошибка отправки данных на сервер.");
     }
  }

// Советник Expert tick function
void OnTick()
  {
// Проверяем прошло ли уже 10 секунд с момента последнего запроса
   if(TimeCurrent() - lastRequestTime >= 10)
     {
      double balance = AccountBalance();
      double equity = AccountEquity();
      double free_margin = AccountFreeMargin();

      // Отправляем данные на сервер
      SendDataToServer(balance, equity, free_margin);

      // Обновляем время последнего запроса
      lastRequestTime = TimeCurrent();
     }
  }
//+------------------------------------------------------------------+
