Get-ADComputer -SearchBase 'ou=Отдел технического обеспечения,ou=сотрудники,ou=SOUNB_PC,DC=uraic,DC=ru' -Filter 'Name -like "OTO*"' -Properties * | Format-Table Name > D:\export.txt

Get-ADUser -SearchBase 'ou=Иностранный отдел,ou=Сотрудники,ou=SOUNB_USERS,DC=uraic,DC=ru' -Filter 'Name -like "ino*"' -Properties * | Format-Table UserPrincipalName,LastBadPasswordAttempt >> D:\export.txt


