
00010074 <main>:
    10074:        00000513        addi x10 x0 0
    10078:        00008067        jalr x0 x1 0

0001007c <register_fini>:
    1007c:        00000793        addi x15 x0 0
    10080:        00078863        beq x15 x0 16
    10084:        00011537        lui x10 0x11
    10088:        8dc50513        addi x10 x10 -1828
    1008c:        0ad0006f        jal x0 2220 <atexit>
    10090:        00008067        jalr x0 x1 0

00010094 <_start>:
    10094:        00002197        auipc x3 0x2
    10098:        29c18193        addi x3 x3 668
    1009c:        c3418513        addi x10 x3 -972
    100a0:        c5018613        addi x12 x3 -944
    100a4:        40a60633        sub x12 x12 x10
    100a8:        00000593        addi x11 x0 0
    100ac:        634000ef        jal x1 1588 <memset>
    100b0:        00001517        auipc x10 0x1
    100b4:        88850513        addi x10 x10 -1912
    100b8:        00050863        beq x10 x0 16
    100bc:        00001517        auipc x10 0x1
    100c0:        82050513        addi x10 x10 -2016
    100c4:        075000ef        jal x1 2164 <atexit>
    100c8:        57c000ef        jal x1 1404 <__libc_init_array>
    100cc:        00012503        lw x10 0 x2
    100d0:        00410593        addi x11 x2 4
    100d4:        00000613        addi x12 x0 0
    100d8:        f9dff0ef        jal x1 -100 <main>
    100dc:        5380006f        jal x0 1336 <exit>

000100e0 <__do_global_dtors_aux>:
    100e0:        ff010113        addi x2 x2 -16
    100e4:        00812423        sw x8 8 x2
    100e8:        c341c783        lbu x15 -972 x3
    100ec:        00112623        sw x1 12 x2
    100f0:        02079263        bne x15 x0 36
    100f4:        00000793        addi x15 x0 0
    100f8:        00078a63        beq x15 x0 20
    100fc:        00012537        lui x10 0x12
    10100:        b1c50513        addi x10 x10 -1252
    10104:        00000097        auipc x1 0x0
    10108:        000000e7        jalr x1 x0 0
    1010c:        00100793        addi x15 x0 1
    10110:        c2f18a23        sb x15 -972 x3
    10114:        00c12083        lw x1 12 x2
    10118:        00812403        lw x8 8 x2
    1011c:        01010113        addi x2 x2 16
    10120:        00008067        jalr x0 x1 0

00010124 <frame_dummy>:
    10124:        00000793        addi x15 x0 0
    10128:        00078c63        beq x15 x0 24
    1012c:        00012537        lui x10 0x12
    10130:        c3818593        addi x11 x3 -968
    10134:        b1c50513        addi x10 x10 -1252
    10138:        00000317        auipc x6 0x0
    1013c:        00000067        jalr x0 x0 0
    10140:        00008067        jalr x0 x1 0

00010144 <myadd>:
    10144:        ff010113        addi x2 x2 -16
    10148:        00812423        sw x8 8 x2
    1014c:        0005a583        lw x11 0 x11
    10150:        00050413        addi x8 x10 0
    10154:        00052503        lw x10 0 x10
    10158:        00112623        sw x1 12 x2
    1015c:        018000ef        jal x1 24 <__addsf3>
    10160:        00c12083        lw x1 12 x2
    10164:        00a42023        sw x10 0 x8
    10168:        00812403        lw x8 8 x2
    1016c:        01010113        addi x2 x2 16
    10170:        00008067        jalr x0 x1 0

00010174 <__addsf3>:
    10174:        00800737        lui x14 0x800
    10178:        ff010113        addi x2 x2 -16
    1017c:        fff70713        addi x14 x14 -1
    10180:        00a777b3        and x15 x14 x10
    10184:        00812423        sw x8 8 x2
    10188:        00912223        sw x9 4 x2
    1018c:        01755413        srli x8 x10 23
    10190:        01f55493        srli x9 x10 31
    10194:        0175d513        srli x10 x11 23
    10198:        00b77733        and x14 x14 x11
    1019c:        0ff47413        andi x8 x8 255
    101a0:        0ff57513        andi x10 x10 255
    101a4:        00112623        sw x1 12 x2
    101a8:        01212023        sw x18 0 x2
    101ac:        01f5d593        srli x11 x11 31
    101b0:        00379793        slli x15 x15 3
    101b4:        00371713        slli x14 x14 3
    101b8:        40a406b3        sub x13 x8 x10
    101bc:        18b49663        bne x9 x11 396
    101c0:        0ad05863        bge x0 x13 176
    101c4:        04051063        bne x10 x0 64
    101c8:        02070063        beq x14 x0 32
    101cc:        fff40693        addi x13 x8 -1
    101d0:        00069863        bne x13 x0 16
    101d4:        00e787b3        add x15 x15 x14
    101d8:        00100413        addi x8 x0 1
    101dc:        0600006f        jal x0 96
    101e0:        0ff00613        addi x12 x0 255
    101e4:        02c41863        bne x8 x12 48
    101e8:        0077f713        andi x14 x15 7
    101ec:        34070a63        beq x14 x0 852
    101f0:        00f7f713        andi x14 x15 15
    101f4:        00400693        addi x13 x0 4
    101f8:        34d70463        beq x14 x13 840
    101fc:        00478793        addi x15 x15 4
    10200:        3400006f        jal x0 832
    10204:        0ff00613        addi x12 x0 255
    10208:        fec400e3        beq x8 x12 -32
    1020c:        04000637        lui x12 0x4000
    10210:        00c76733        or x14 x14 x12
    10214:        01b00593        addi x11 x0 27
    10218:        00100613        addi x12 x0 1
    1021c:        00d5ce63        blt x11 x13 28
    10220:        02000613        addi x12 x0 32
    10224:        00d755b3        srl x11 x14 x13
    10228:        40d606b3        sub x13 x12 x13
    1022c:        00d71733        sll x14 x14 x13
    10230:        00e03733        sltu x14 x0 x14
    10234:        00e5e633        or x12 x11 x14
    10238:        00c787b3        add x15 x15 x12
    1023c:        04000737        lui x14 0x4000
    10240:        00e7f733        and x14 x15 x14
    10244:        fa0702e3        beq x14 x0 -92
    10248:        00140413        addi x8 x8 1
    1024c:        0ff00713        addi x14 x0 255
    10250:        2ee40663        beq x8 x14 748
    10254:        7e000737        lui x14 0x7e000
    10258:        0017f693        andi x13 x15 1
    1025c:        fff70713        addi x14 x14 -1
    10260:        0017d793        srli x15 x15 1
    10264:        00e7f7b3        and x15 x15 x14
    10268:        00d7e7b3        or x15 x15 x13
    1026c:        f7dff06f        jal x0 -132
    10270:        06068663        beq x13 x0 108
    10274:        408506b3        sub x13 x10 x8
    10278:        02041063        bne x8 x0 32
    1027c:        2a078663        beq x15 x0 684
    10280:        fff68613        addi x12 x13 -1
    10284:        f40608e3        beq x12 x0 -176
    10288:        0ff00593        addi x11 x0 255
    1028c:        02b69063        bne x13 x11 32
    10290:        00070793        addi x15 x14 0
    10294:        2100006f        jal x0 528
    10298:        0ff00613        addi x12 x0 255
    1029c:        fec50ae3        beq x10 x12 -12
    102a0:        04000637        lui x12 0x4000
    102a4:        00c7e7b3        or x15 x15 x12
    102a8:        00068613        addi x12 x13 0
    102ac:        01b00593        addi x11 x0 27
    102b0:        00100693        addi x13 x0 1
    102b4:        00c5ce63        blt x11 x12 28
    102b8:        02000693        addi x13 x0 32
    102bc:        40c686b3        sub x13 x13 x12
    102c0:        00c7d5b3        srl x11 x15 x12
    102c4:        00d797b3        sll x15 x15 x13
    102c8:        00f037b3        sltu x15 x0 x15
    102cc:        00f5e6b3        or x13 x11 x15
    102d0:        00e687b3        add x15 x13 x14
    102d4:        00050413        addi x8 x10 0
    102d8:        f65ff06f        jal x0 -156
    102dc:        00140693        addi x13 x8 1
    102e0:        0fe6f613        andi x12 x13 254
    102e4:        04061663        bne x12 x0 76
    102e8:        02041863        bne x8 x0 48
    102ec:        24078263        beq x15 x0 580
    102f0:        ee070ce3        beq x14 x0 -264
    102f4:        00e787b3        add x15 x15 x14
    102f8:        04000737        lui x14 0x4000
    102fc:        00e7f733        and x14 x15 x14
    10300:        ee0704e3        beq x14 x0 -280
    10304:        fc000737        lui x14 0xfc000
    10308:        fff70713        addi x14 x14 -1
    1030c:        00e7f7b3        and x15 x15 x14
    10310:        00100413        addi x8 x0 1
    10314:        ed5ff06f        jal x0 -300
    10318:        f6078ce3        beq x15 x0 -136
    1031c:        18070463        beq x14 x0 392
    10320:        00000493        addi x9 x0 0
    10324:        020007b7        lui x15 0x2000
    10328:        0ff00413        addi x8 x0 255
    1032c:        2140006f        jal x0 532
    10330:        0ff00613        addi x12 x0 255
    10334:        20c68263        beq x13 x12 516
    10338:        00e78733        add x14 x15 x14
    1033c:        00175793        srli x15 x14 1
    10340:        00068413        addi x8 x13 0
    10344:        ea5ff06f        jal x0 -348
    10348:        06d05e63        bge x0 x13 124
    1034c:        06051263        bne x10 x0 100
    10350:        e8070ce3        beq x14 x0 -360
    10354:        fff40693        addi x13 x8 -1
    10358:        00069863        bne x13 x0 16
    1035c:        40e787b3        sub x15 x15 x14
    10360:        00100413        addi x8 x0 1
    10364:        0340006f        jal x0 52
    10368:        0ff00613        addi x12 x0 255
    1036c:        e6c40ee3        beq x8 x12 -388
    10370:        01b00593        addi x11 x0 27
    10374:        00100613        addi x12 x0 1
    10378:        00d5ce63        blt x11 x13 28
    1037c:        02000613        addi x12 x0 32
    10380:        00d755b3        srl x11 x14 x13
    10384:        40d606b3        sub x13 x12 x13
    10388:        00d71733        sll x14 x14 x13
    1038c:        00e03733        sltu x14 x0 x14
    10390:        00e5e633        or x12 x11 x14
    10394:        40c787b3        sub x15 x15 x12
    10398:        04000937        lui x18 0x4000
    1039c:        0127f733        and x14 x15 x18
    103a0:        e40704e3        beq x14 x0 -440
    103a4:        fff90913        addi x18 x18 -1
    103a8:        0127f933        and x18 x15 x18
    103ac:        1180006f        jal x0 280
    103b0:        0ff00613        addi x12 x0 255
    103b4:        e2c40ae3        beq x8 x12 -460
    103b8:        04000637        lui x12 0x4000
    103bc:        00c76733        or x14 x14 x12
    103c0:        fb1ff06f        jal x0 -80
    103c4:        08068063        beq x13 x0 128
    103c8:        408506b3        sub x13 x10 x8
    103cc:        02041863        bne x8 x0 48
    103d0:        1e078263        beq x15 x0 484
    103d4:        fff68613        addi x12 x13 -1
    103d8:        00061863        bne x12 x0 16
    103dc:        40f707b3        sub x15 x14 x15
    103e0:        00058493        addi x9 x11 0
    103e4:        f7dff06f        jal x0 -132
    103e8:        0ff00813        addi x16 x0 255
    103ec:        03069263        bne x13 x16 36
    103f0:        00070793        addi x15 x14 0
    103f4:        0ff00413        addi x8 x0 255
    103f8:        06c0006f        jal x0 108
    103fc:        0ff00613        addi x12 x0 255
    10400:        fec508e3        beq x10 x12 -16
    10404:        04000637        lui x12 0x4000
    10408:        00c7e7b3        or x15 x15 x12
    1040c:        00068613        addi x12 x13 0
    10410:        01b00813        addi x16 x0 27
    10414:        00100693        addi x13 x0 1
    10418:        00c84e63        blt x16 x12 28
    1041c:        02000693        addi x13 x0 32
    10420:        40c686b3        sub x13 x13 x12
    10424:        00c7d833        srl x16 x15 x12
    10428:        00d797b3        sll x15 x15 x13
    1042c:        00f037b3        sltu x15 x0 x15
    10430:        00f866b3        or x13 x16 x15
    10434:        40d707b3        sub x15 x14 x13
    10438:        00050413        addi x8 x10 0
    1043c:        00058493        addi x9 x11 0
    10440:        f59ff06f        jal x0 -168
    10444:        00140693        addi x13 x8 1
    10448:        0fe6f693        andi x13 x13 254
    1044c:        06069063        bne x13 x0 96
    10450:        04041263        bne x8 x0 68
    10454:        00079c63        bne x15 x0 24
    10458:        00000493        addi x9 x0 0
    1045c:        0e070263        beq x14 x0 228
    10460:        00070793        addi x15 x14 0
    10464:        00058493        addi x9 x11 0
    10468:        d81ff06f        jal x0 -640
    1046c:        d6070ee3        beq x14 x0 -644
    10470:        40e786b3        sub x13 x15 x14
    10474:        04000637        lui x12 0x4000
    10478:        00c6f633        and x12 x13 x12
    1047c:        40f707b3        sub x15 x14 x15
    10480:        fe0612e3        bne x12 x0 -28
    10484:        00000793        addi x15 x0 0
    10488:        08068263        beq x13 x0 132
    1048c:        00068793        addi x15 x13 0
    10490:        d59ff06f        jal x0 -680
    10494:        e80794e3        bne x15 x0 -376
    10498:        e80704e3        beq x14 x0 -376
    1049c:        00070793        addi x15 x14 0
    104a0:        00058493        addi x9 x11 0
    104a4:        0ff00413        addi x8 x0 255
    104a8:        d41ff06f        jal x0 -704
    104ac:        40e78933        sub x18 x15 x14
    104b0:        040006b7        lui x13 0x4000
    104b4:        00d976b3        and x13 x18 x13
    104b8:        04068463        beq x13 x0 72
    104bc:        40f70933        sub x18 x14 x15
    104c0:        00058493        addi x9 x11 0
    104c4:        00090513        addi x10 x18 0
    104c8:        100000ef        jal x1 256 <__clzsi2>
    104cc:        ffb50513        addi x10 x10 -5
    104d0:        00a91933        sll x18 x18 x10
    104d4:        04854063        blt x10 x8 64
    104d8:        40850533        sub x10 x10 x8
    104dc:        00150513        addi x10 x10 1
    104e0:        02000713        addi x14 x0 32
    104e4:        40a70733        sub x14 x14 x10
    104e8:        00a957b3        srl x15 x18 x10
    104ec:        00e91933        sll x18 x18 x14
    104f0:        01203933        sltu x18 x0 x18
    104f4:        0127e7b3        or x15 x15 x18
    104f8:        00000413        addi x8 x0 0
    104fc:        cedff06f        jal x0 -788
    10500:        fc0912e3        bne x18 x0 -60
    10504:        00000793        addi x15 x0 0
    10508:        00000413        addi x8 x0 0
    1050c:        00000493        addi x9 x0 0
    10510:        0300006f        jal x0 48
    10514:        fc0007b7        lui x15 0xfc000
    10518:        fff78793        addi x15 x15 -1
    1051c:        40a40433        sub x8 x8 x10
    10520:        00f977b3        and x15 x18 x15
    10524:        cc5ff06f        jal x0 -828
    10528:        00070793        addi x15 x14 0
    1052c:        e15ff06f        jal x0 -492
    10530:        00070793        addi x15 x14 0
    10534:        cb5ff06f        jal x0 -844
    10538:        0ff00413        addi x8 x0 255
    1053c:        00000793        addi x15 x0 0
    10540:        04000737        lui x14 0x4000
    10544:        00e7f733        and x14 x15 x14
    10548:        00070e63        beq x14 x0 28
    1054c:        00140413        addi x8 x8 1
    10550:        0ff00713        addi x14 x0 255
    10554:        06e40663        beq x8 x14 108
    10558:        fc000737        lui x14 0xfc000
    1055c:        fff70713        addi x14 x14 -1
    10560:        00e7f7b3        and x15 x15 x14
    10564:        0ff00713        addi x14 x0 255
    10568:        0037d793        srli x15 x15 3
    1056c:        00e41863        bne x8 x14 16
    10570:        00078663        beq x15 x0 12
    10574:        004007b7        lui x15 0x400
    10578:        00000493        addi x9 x0 0
    1057c:        01741413        slli x8 x8 23
    10580:        7f800737        lui x14 0x7f800
    10584:        00979793        slli x15 x15 9
    10588:        00e47433        and x8 x8 x14
    1058c:        0097d793        srli x15 x15 9
    10590:        00f46433        or x8 x8 x15
    10594:        01f49513        slli x10 x9 31
    10598:        00c12083        lw x1 12 x2
    1059c:        00a46533        or x10 x8 x10
    105a0:        00812403        lw x8 8 x2
    105a4:        00412483        lw x9 4 x2
    105a8:        00012903        lw x18 0 x2
    105ac:        01010113        addi x2 x2 16
    105b0:        00008067        jalr x0 x1 0
    105b4:        00070793        addi x15 x14 0
    105b8:        00068413        addi x8 x13 0
    105bc:        ea9ff06f        jal x0 -344
    105c0:        00000793        addi x15 x0 0
    105c4:        fa1ff06f        jal x0 -96

000105c8 <__clzsi2>:
    105c8:        000107b7        lui x15 0x10
    105cc:        02f57a63        bgeu x10 x15 52
    105d0:        10053793        sltiu x15 x10 256
    105d4:        0017c793        xori x15 x15 1
    105d8:        00379793        slli x15 x15 3
    105dc:        00011737        lui x14 0x11
    105e0:        02000693        addi x13 x0 32
    105e4:        40f686b3        sub x13 x13 x15
    105e8:        00f55533        srl x10 x10 x15
    105ec:        a1c70793        addi x15 x14 -1508
    105f0:        00a787b3        add x15 x15 x10
    105f4:        0007c503        lbu x10 0 x15
    105f8:        40a68533        sub x10 x13 x10
    105fc:        00008067        jalr x0 x1 0
    10600:        01000737        lui x14 0x1000
    10604:        01000793        addi x15 x0 16
    10608:        fce56ae3        bltu x10 x14 -44
    1060c:        01800793        addi x15 x0 24
    10610:        fcdff06f        jal x0 -52

00010614 <exit>:
    10614:        ff010113        addi x2 x2 -16
    10618:        00000593        addi x11 x0 0
    1061c:        00812423        sw x8 8 x2
    10620:        00112623        sw x1 12 x2
    10624:        00050413        addi x8 x10 0
    10628:        194000ef        jal x1 404 <__call_exitprocs>
    1062c:        c281a503        lw x10 -984 x3
    10630:        03c52783        lw x15 60 x10
    10634:        00078463        beq x15 x0 8
    10638:        000780e7        jalr x1 x15 0
    1063c:        00040513        addi x10 x8 0
    10640:        3a4000ef        jal x1 932 <_exit>

00010644 <__libc_init_array>:
    10644:        ff010113        addi x2 x2 -16
    10648:        00812423        sw x8 8 x2
    1064c:        01212023        sw x18 0 x2
    10650:        00012437        lui x8 0x12
    10654:        00012937        lui x18 0x12
    10658:        b2040793        addi x15 x8 -1248
    1065c:        b2090913        addi x18 x18 -1248
    10660:        40f90933        sub x18 x18 x15
    10664:        00112623        sw x1 12 x2
    10668:        00912223        sw x9 4 x2
    1066c:        40295913        srai x18 x18 2
    10670:        02090063        beq x18 x0 32
    10674:        b2040413        addi x8 x8 -1248
    10678:        00000493        addi x9 x0 0
    1067c:        00042783        lw x15 0 x8
    10680:        00148493        addi x9 x9 1
    10684:        00440413        addi x8 x8 4
    10688:        000780e7        jalr x1 x15 0
    1068c:        fe9918e3        bne x18 x9 -16
    10690:        00012437        lui x8 0x12
    10694:        00012937        lui x18 0x12
    10698:        b2040793        addi x15 x8 -1248
    1069c:        b2890913        addi x18 x18 -1240
    106a0:        40f90933        sub x18 x18 x15
    106a4:        40295913        srai x18 x18 2
    106a8:        02090063        beq x18 x0 32
    106ac:        b2040413        addi x8 x8 -1248
    106b0:        00000493        addi x9 x0 0
    106b4:        00042783        lw x15 0 x8
    106b8:        00148493        addi x9 x9 1
    106bc:        00440413        addi x8 x8 4
    106c0:        000780e7        jalr x1 x15 0
    106c4:        fe9918e3        bne x18 x9 -16
    106c8:        00c12083        lw x1 12 x2
    106cc:        00812403        lw x8 8 x2
    106d0:        00412483        lw x9 4 x2
    106d4:        00012903        lw x18 0 x2
    106d8:        01010113        addi x2 x2 16
    106dc:        00008067        jalr x0 x1 0

000106e0 <memset>:
    106e0:        00f00313        addi x6 x0 15
    106e4:        00050713        addi x14 x10 0
    106e8:        02c37e63        bgeu x6 x12 60
    106ec:        00f77793        andi x15 x14 15
    106f0:        0a079063        bne x15 x0 160
    106f4:        08059263        bne x11 x0 132
    106f8:        ff067693        andi x13 x12 -16
    106fc:        00f67613        andi x12 x12 15
    10700:        00e686b3        add x13 x13 x14
    10704:        00b72023        sw x11 0 x14
    10708:        00b72223        sw x11 4 x14
    1070c:        00b72423        sw x11 8 x14
    10710:        00b72623        sw x11 12 x14
    10714:        01070713        addi x14 x14 16
    10718:        fed766e3        bltu x14 x13 -20
    1071c:        00061463        bne x12 x0 8
    10720:        00008067        jalr x0 x1 0
    10724:        40c306b3        sub x13 x6 x12
    10728:        00269693        slli x13 x13 2
    1072c:        00000297        auipc x5 0x0
    10730:        005686b3        add x13 x13 x5
    10734:        00c68067        jalr x0 x13 12
    10738:        00b70723        sb x11 14 x14
    1073c:        00b706a3        sb x11 13 x14
    10740:        00b70623        sb x11 12 x14
    10744:        00b705a3        sb x11 11 x14
    10748:        00b70523        sb x11 10 x14
    1074c:        00b704a3        sb x11 9 x14
    10750:        00b70423        sb x11 8 x14
    10754:        00b703a3        sb x11 7 x14
    10758:        00b70323        sb x11 6 x14
    1075c:        00b702a3        sb x11 5 x14
    10760:        00b70223        sb x11 4 x14
    10764:        00b701a3        sb x11 3 x14
    10768:        00b70123        sb x11 2 x14
    1076c:        00b700a3        sb x11 1 x14
    10770:        00b70023        sb x11 0 x14
    10774:        00008067        jalr x0 x1 0
    10778:        0ff5f593        andi x11 x11 255
    1077c:        00859693        slli x13 x11 8
    10780:        00d5e5b3        or x11 x11 x13
    10784:        01059693        slli x13 x11 16
    10788:        00d5e5b3        or x11 x11 x13
    1078c:        f6dff06f        jal x0 -148
    10790:        00279693        slli x13 x15 2
    10794:        00000297        auipc x5 0x0
    10798:        005686b3        add x13 x13 x5
    1079c:        00008293        addi x5 x1 0
    107a0:        fa0680e7        jalr x1 x13 -96
    107a4:        00028093        addi x1 x5 0
    107a8:        ff078793        addi x15 x15 -16
    107ac:        40f70733        sub x14 x14 x15
    107b0:        00f60633        add x12 x12 x15
    107b4:        f6c378e3        bgeu x6 x12 -144
    107b8:        f3dff06f        jal x0 -196

000107bc <__call_exitprocs>:
    107bc:        fd010113        addi x2 x2 -48
    107c0:        01412c23        sw x20 24 x2
    107c4:        c281aa03        lw x20 -984 x3
    107c8:        03212023        sw x18 32 x2
    107cc:        02112623        sw x1 44 x2
    107d0:        148a2903        lw x18 328 x20
    107d4:        02812423        sw x8 40 x2
    107d8:        02912223        sw x9 36 x2
    107dc:        01312e23        sw x19 28 x2
    107e0:        01512a23        sw x21 20 x2
    107e4:        01612823        sw x22 16 x2
    107e8:        01712623        sw x23 12 x2
    107ec:        01812423        sw x24 8 x2
    107f0:        04090063        beq x18 x0 64
    107f4:        00050b13        addi x22 x10 0
    107f8:        00058b93        addi x23 x11 0
    107fc:        00100a93        addi x21 x0 1
    10800:        fff00993        addi x19 x0 -1
    10804:        00492483        lw x9 4 x18
    10808:        fff48413        addi x8 x9 -1
    1080c:        02044263        blt x8 x0 36
    10810:        00249493        slli x9 x9 2
    10814:        009904b3        add x9 x18 x9
    10818:        040b8463        beq x23 x0 72
    1081c:        1044a783        lw x15 260 x9
    10820:        05778063        beq x15 x23 64
    10824:        fff40413        addi x8 x8 -1
    10828:        ffc48493        addi x9 x9 -4
    1082c:        ff3416e3        bne x8 x19 -20
    10830:        02c12083        lw x1 44 x2
    10834:        02812403        lw x8 40 x2
    10838:        02412483        lw x9 36 x2
    1083c:        02012903        lw x18 32 x2
    10840:        01c12983        lw x19 28 x2
    10844:        01812a03        lw x20 24 x2
    10848:        01412a83        lw x21 20 x2
    1084c:        01012b03        lw x22 16 x2
    10850:        00c12b83        lw x23 12 x2
    10854:        00812c03        lw x24 8 x2
    10858:        03010113        addi x2 x2 48
    1085c:        00008067        jalr x0 x1 0
    10860:        00492783        lw x15 4 x18
    10864:        0044a683        lw x13 4 x9
    10868:        fff78793        addi x15 x15 -1
    1086c:        04878e63        beq x15 x8 92
    10870:        0004a223        sw x0 4 x9
    10874:        fa0688e3        beq x13 x0 -80
    10878:        18892783        lw x15 392 x18
    1087c:        008a9733        sll x14 x21 x8
    10880:        00492c03        lw x24 4 x18
    10884:        00f777b3        and x15 x14 x15
    10888:        02079263        bne x15 x0 36
    1088c:        000680e7        jalr x1 x13 0
    10890:        00492703        lw x14 4 x18
    10894:        148a2783        lw x15 328 x20
    10898:        01871463        bne x14 x24 8
    1089c:        f92784e3        beq x15 x18 -120
    108a0:        f80788e3        beq x15 x0 -112
    108a4:        00078913        addi x18 x15 0
    108a8:        f5dff06f        jal x0 -164
    108ac:        18c92783        lw x15 396 x18
    108b0:        0844a583        lw x11 132 x9
    108b4:        00f77733        and x14 x14 x15
    108b8:        00071c63        bne x14 x0 24
    108bc:        000b0513        addi x10 x22 0
    108c0:        000680e7        jalr x1 x13 0
    108c4:        fcdff06f        jal x0 -52
    108c8:        00892223        sw x8 4 x18
    108cc:        fa9ff06f        jal x0 -88
    108d0:        00058513        addi x10 x11 0
    108d4:        000680e7        jalr x1 x13 0
    108d8:        fb9ff06f        jal x0 -72

000108dc <__libc_fini_array>:
    108dc:        ff010113        addi x2 x2 -16
    108e0:        00812423        sw x8 8 x2
    108e4:        000127b7        lui x15 0x12
    108e8:        00012437        lui x8 0x12
    108ec:        b2878793        addi x15 x15 -1240
    108f0:        b2c40413        addi x8 x8 -1236
    108f4:        40f40433        sub x8 x8 x15
    108f8:        00912223        sw x9 4 x2
    108fc:        00112623        sw x1 12 x2
    10900:        40245493        srai x9 x8 2
    10904:        02048063        beq x9 x0 32
    10908:        ffc40413        addi x8 x8 -4
    1090c:        00f40433        add x8 x8 x15
    10910:        00042783        lw x15 0 x8
    10914:        fff48493        addi x9 x9 -1
    10918:        ffc40413        addi x8 x8 -4
    1091c:        000780e7        jalr x1 x15 0
    10920:        fe0498e3        bne x9 x0 -16
    10924:        00c12083        lw x1 12 x2
    10928:        00812403        lw x8 8 x2
    1092c:        00412483        lw x9 4 x2
    10930:        01010113        addi x2 x2 16
    10934:        00008067        jalr x0 x1 0

00010938 <atexit>:
    10938:        00050593        addi x11 x10 0
    1093c:        00000693        addi x13 x0 0
    10940:        00000613        addi x12 x0 0
    10944:        00000513        addi x10 x0 0
    10948:        0040006f        jal x0 4 <__register_exitproc>

0001094c <__register_exitproc>:
    1094c:        c281a703        lw x14 -984 x3
    10950:        14872783        lw x15 328 x14
    10954:        04078c63        beq x15 x0 88
    10958:        0047a703        lw x14 4 x15
    1095c:        01f00813        addi x16 x0 31
    10960:        06e84e63        blt x16 x14 124
    10964:        00271813        slli x16 x14 2
    10968:        02050663        beq x10 x0 44
    1096c:        01078333        add x6 x15 x16
    10970:        08c32423        sw x12 136 x6
    10974:        1887a883        lw x17 392 x15
    10978:        00100613        addi x12 x0 1
    1097c:        00e61633        sll x12 x12 x14
    10980:        00c8e8b3        or x17 x17 x12
    10984:        1917a423        sw x17 392 x15
    10988:        10d32423        sw x13 264 x6
    1098c:        00200693        addi x13 x0 2
    10990:        02d50463        beq x10 x13 40
    10994:        00170713        addi x14 x14 1
    10998:        00e7a223        sw x14 4 x15
    1099c:        010787b3        add x15 x15 x16
    109a0:        00b7a423        sw x11 8 x15
    109a4:        00000513        addi x10 x0 0
    109a8:        00008067        jalr x0 x1 0
    109ac:        14c70793        addi x15 x14 332
    109b0:        14f72423        sw x15 328 x14
    109b4:        fa5ff06f        jal x0 -92
    109b8:        18c7a683        lw x13 396 x15
    109bc:        00170713        addi x14 x14 1
    109c0:        00e7a223        sw x14 4 x15
    109c4:        00c6e6b3        or x13 x13 x12
    109c8:        18d7a623        sw x13 396 x15
    109cc:        010787b3        add x15 x15 x16
    109d0:        00b7a423        sw x11 8 x15
    109d4:        00000513        addi x10 x0 0
    109d8:        00008067        jalr x0 x1 0
    109dc:        fff00513        addi x10 x0 -1
    109e0:        00008067        jalr x0 x1 0

000109e4 <_exit>:
    109e4:        05d00893        addi x17 x0 93
    109e8:        00000073        ecall
    109ec:        00054463        blt x10 x0 8
    109f0:        0000006f        jal x0 0
    109f4:        ff010113        addi x2 x2 -16
    109f8:        00812423        sw x8 8 x2
    109fc:        00050413        addi x8 x10 0
    10a00:        00112623        sw x1 12 x2
    10a04:        40800433        sub x8 x0 x8
    10a08:        00c000ef        jal x1 12 <__errno>
    10a0c:        00852023        sw x8 0 x10
    10a10:        0000006f        jal x0 0

00010a14 <__errno>:
    10a14:        c301a503        lw x10 -976 x3
    10a18:        00008067        jalr x0 x1 0