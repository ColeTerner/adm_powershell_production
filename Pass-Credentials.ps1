#ПЕРЕДАЧА УЧЕТНЫХ ДАННЫХ В POWERSHELL

#Сохранение учетных данных в PS

#1.Записываем переменные логина и пароля
$username = 'Roman@uraic.ru'
$password='Flatron1751'

#2.Конвертируем переменную пароля в зашифрованную строку (атрибут -AsPlainText присваивает значение расшифрованного текста , -Force избавляет от запросов PS)
$sec_password= ConvertTo-SecureString $password -AsPlainText -Force

#3. Создание нового объекта учетных данных из библиотеки  (System.Management.Automation.PSCredential) !!!
$creds=New-Object System.Management.Automation.PSCredential -ArgumentList $username,$sec_password 

#ПРИМЕР: Открытие новой PS сессии , используя учетные данные 
New-PSSession -ComputerName zayl.uraic.ru -Name ZAYLOK -Credential $creds



