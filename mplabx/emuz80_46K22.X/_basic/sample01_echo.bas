10 KB=0
20 PA=INP(&HD0)
30 OUT &HD0,PA

40 KA=INP(&HE0)
50 IF KA=KB GOTO 20
60 KB=KA
70 GOSUB 200
80 GOTO 20

200 REM SEND PROCESS
210 SA=INP(&HE1)
220 SB=SA AND &H02
230 IF SB=0 GOTO 210
240 OUT &HE0,KA
250 RETURN

300 END
