# Fingerprints of the holes

Prologue, resolved constants, `0x8xxxxxxx` status codes and callees.
Callee tags: `read` = has a Ghidra C file in the corpus, `hole` = another listed hole.


## `0x9803da18`
prologue: lis r11, 0x124 | stfs f1, -0x20(r1) | lwz r10, -0x20(r1) | lis r9, -0x6800 | ori r11, r11, 0x3f6d
consts: 0.159155 6.28319 2.75573e-06 1
status: -
callees: -

## `0x9803ee60`
prologue: mflr r12 | bl 0x980618b8 | stwu r1, -0x100(r1) | VMX-6-p06(undecoded) | addi r29, r1, 0x70
consts: -
status: -
callees: 0x980618b8(read) 0x9803e930 0x9803e1b8 0x98087d38(read)

## `0x9803f920`
prologue: mflr r12 | stw r12, -8(r1) | std r31, -0x10(r1) | stwu r1, -0x80(r1) | VMX-6-p06(undecoded)
consts: -
status: -
callees: 0x9803f540 0x9803f920(read)

## `0x9803faa8`
prologue: mflr r12 | stw r12, -8(r1) | std r31, -0x10(r1) | stwu r1, -0xb0(r1) | lis r9, -0x6800
consts: -
status: -
callees: 0x9803f920(read)

## `0x98042498`
prologue: mflr r12 | bl 0x980618cc | stwu r1, -0xb0(r1) | mr r31, r3 | mr r11, r4
consts: -
status: -
callees: 0x980618cc(read) 0x9808c820(read) 0x98085a58(read) 0x980831d0(read) 0x9808c398(read) 0x9808c650(read) 0x9808c178(read) 0x98083da8(read) 0x980836d8(read) 0x980836d8(read) 0x9808d798(read) 0x98083da8(read)

## `0x98043b70`
prologue: mflr r12 | bl 0x980618b8 | stfd f30, -0x58(r1) | stfd f31, -0x50(r1) | li r12, -0x80
consts: 1 6 0.02
status: -
callees: 0x980618b8(read) 0x98087d38(read) 0x98082e98(read) 0x98085c90(read) 0x980830f0(read) 0x98087d38(read) 0x98058050 0x98062720(read) 0x98042408 0x9808a118(read) 0x98088a80(read) 0x98088b50(read) 0x980836d8(read) 0x98083d68(read) 0x98083da8(read) 0x98083e10 0x98083e88 0x98083640(read) 0x98043978 0x9808a958(read) 0x98088b98(read) 0x98088af8(read) 0x98043030(read) 0x98063a30(read)

## `0x9804a010`
prologue: mflr r12 | bl 0x980618cc | addi r12, r1, -0x20 | bl 0x98063abc | addi r12, r1, -0x60
consts: 2.3927 1 5 -1 8
status: -
callees: 0x980618cc(read) 0x98063abc(read) 0x98062ec4(read) 0x980415d0(read) 0x98063180(read) 0x98063180(read) 0x98063180(read) 0x9803faa8(read) 0x98047ab0(read) 0x9806315c(read) 0x98063b08(read) 0x980489c0 0x98048448(read) 0x9804a010(read) 0x9805c5a0(read)

## `0x9804d2f8`
prologue: mflr r12 | bl 0x980618cc | stwu r1, -0xa0(r1) | addi r11, r4, -1 | mr r31, r3
consts: ";>;"
status: -
callees: 0x980618cc(read) 0x98055570(read) 0x98056680(read) 0x9803f6e0(read) 0x98055ef8(read) 0x98055570(read) 0x9804d2f8(read) 0x98056680(read) 0x98056298(read)

## `0x98055cd8`
prologue: addi r11, r3, -2 | cmplwi cr6, r11, 0x37 | bgt cr6, 0x98055ea4 | lis r12, -0x6800 | addi r12, r12, 0x4dd0
consts: -
status: -
callees: 0x98055cd8(read)

## `0x98055ef8`
prologue: addi r11, r4, -1 | cmplwi cr6, r11, 0x30 | bgt cr6, 0x980560e0 | lis r12, -0x6800 | addi r12, r12, 0x4e08
consts: -
status: -
callees: -

## `0x98058268`
prologue: mflr r12 | stw r12, -8(r1) | stwu r1, -0x70(r1) | VMX-5-p05(undecoded) | VMX-6-p06(undecoded)
consts: -1 1.5708 1
status: -
callees: 0x98057c18 0x98063ac8(read) 0x98058268(read) 0x98058268(read) 0x98058268(read) 0x98058268(read) 0x98063b14(read)

## `0x9805bd20`
prologue: b 0x9813b3cc | nop-or-padding | b 0x9813b3fc | nop-or-padding | b 0x9813b40c
consts: -
status: -
callees: 0x9813b41c

## `0x9805be30`
prologue: b 0x9813b45c | nop-or-padding | slwi r11, r4, 6 | slwi r10, r3, 0 | addi r11, r11, 0x103f
consts: -
status: -
callees: -

## `0x9805bef8`
prologue: mr r8, r7 | mr r7, r6 | mr r6, r5 | mr r5, r4 | li r4, 0
consts: -
status: -
callees: -

## `0x9805c648`
prologue: li r4, 3 | b 0x9813b47c
consts: -
status: -
callees: -

## `0x9805d154`
prologue: std r30, -0x10(r1) | std r31, -8(r1) | li r6, -0x20 | li r7, -0x30 | VMX-p04(undecoded)
consts: -
status: -
callees: -

## `0x9805e060`
prologue: b 0x9813b6bc | nop-or-padding
consts: -
status: -
callees: -

## `0x98061950`
prologue: addi r0, r5, 1 | mtctr r0 | ori r6, r3, 0 | b 0x9806196c | addi r5, r5, -1
consts: -
status: -
callees: -

## `0x98062658`
prologue: mflr r12 | stw r12, -8(r1) | std r30, -0x18(r1) | std r31, -0x10(r1) | stwu r1, -0x80(r1)
consts: -
status: -
callees: 0x98067598(read) 0x980674c0(read) 0x98061e30(read) 0x980624d0(read) 0x980675e0(read)

## `0x98065ca0`
prologue: mflr r12 | stw r12, -8(r1) | stwu r1, -0xb00(r1) | li r5, 0xa40 | li r4, 0
consts: -
status: -
callees: 0x98061950(read) 0x9805c738(read) 0x9805c800(read) 0x9806b008(read) 0x9813b83c(read)

## `0x98072978`
prologue: lis r11, -0x6800 | addi r9, r1, -0x10 | addi r8, r1, -0xc | addi r7, r1, -0xc | addi r6, r1, -0x10
consts: 1 1.5 1.9 1.4 1.8 1.6 2.2 0.6
status: -
callees: 0x9806189c(read) 0x98072978(read)

## `0x98075890`
prologue: mflr r12 | bl 0x980618c4 | stfd f29, -0x48(r1) | stfd f30, -0x40(r1) | stfd f31, -0x38(r1)
consts: 1 1e-05
status: -
callees: 0x980618c4(read) 0x98075260(read) 0x980753f0(read) 0x98075260(read) 0x980753f0(read) 0x98058a48(read) 0x98058a48(read) 0x980618c8(read) 0x98075590 0x98075708(read) 0x98075590 0x98075708(read) 0x98058a48(read) 0x98058a48(read) 0x980618b4(read) 0x9807e4d8(read) 0x98075890(read)

## `0x98078670`
prologue: mflr r12 | bl 0x980618ac | stwu r1, -0x180(r1) | mr r25, r6 | vcmpequd v30, v0, v5
consts: -
status: -
callees: 0x980618ac(read) 0x9808c178(read) 0x9808c178(read) 0x9808c338(read) 0x98083640(read) 0x98085090(read) 0x98084ee8 0x98085090(read) 0x98084ee8 0x98085090(read) 0x98084ee8 0x98085090(read) 0x98084ee8 0x98085090(read) 0x98084ee8 0x98085090(read) 0x98084ee8 0x98085090(read) 0x98084ee8 0x98085090(read) 0x98084ee8 0x98085090(read) 0x98084ee8

## `0x9807b318`
prologue: mflr r12 | stw r12, -8(r1) | std r30, -0x18(r1) | std r31, -0x10(r1) | addi r12, r1, -0x18
consts: 0.5
status: -
callees: 0x98063ac4(read) 0x98111258(read) 0x98111338(read) 0x98063b10(read)

## `0x980813e8`
prologue: mflr r12 | stw r12, -8(r1) | std r31, -0x10(r1) | stwu r1, -0xd0(r1) | mr r31, r3
consts: 1
status: -
callees: 0x98062720(read) 0x980863f0(read) 0x980808e8(read) 0x9808a958(read) 0x9808f4f8(read) 0x98086340(read) 0x98085910(read) 0x98080dd8(read)

## `0x9808a118`
prologue: mflr r12 | bl 0x980618c4 | stfd f31, -0x38(r1) | stwu r1, -0xa0(r1) | addi r11, r1, 0xd4
consts: 32896.5 -32896.5 1023 0.0625611 0.125122
status: -
callees: 0x980618c4(read) 0x98089ff0(read) 0x98089ff0(read)

## `0x9808c178`
prologue: std r31, -8(r1) | addi r10, r4, 0x78 | mr r11, r5 | slwi r10, r10, 4 | mr r9, r6
consts: -
status: -
callees: -

## `0x9808c258`
prologue: std r31, -8(r1) | addi r10, r4, 0x178 | mr r11, r5 | slwi r10, r10, 4 | mr r9, r6
consts: -
status: -
callees: -

## `0x9808e288`
prologue: ld r11, 0(r3) | mr r10, r11 | cmplw cr6, r4, r10 | bge cr6, 0x9808e29c | mr r10, r4
consts: -
status: -
callees: -

## `0x9808e2f0`
prologue: li r10, -1 | ld r11, 0(r3) | clrldi r10, r10, 0x20 | mfmsr r8 | mtmsrd r13, 1
consts: -
status: -
callees: -

## `0x98095140`
prologue: lis r11, -0x6800 | stfs f1, 0x14(r1) | addi r10, r1, -0x20 | VMX-6-p06(undecoded) | addi r8, r1, 0x14
consts: 1.44269 0.241874 0.00961598
status: -
callees: -

## `0x98095858`
prologue: mflr r12 | stw r12, -8(r1) | stfd f30, -0x18(r1) | stfd f31, -0x10(r1) | stwu r1, -0x90(r1)
consts: 3.75 0.266667 0.0045813 0.0360768 0.265973 1.20675 3.08994 3.51562 1 0.00392377 0.0164763 0.0263554 0.0205771 0.00916281 0.00157565 0.00225319 0.0132859 0.398942
status: -
callees: 0x980950a0 0x98095370

## `0x9809f590`
prologue: li r11, 0xb | vcmpequd v31, v0, v4 | lvsl v0, 0, r4 | lis r10, -0x67fe | addi r10, r10, 0x5c70
consts: 0.159155 6.28319 1
status: -
callees: -

## `0x9809f610`
prologue: li r11, 0xb | vcmpequd v31, v0, v4 | li r10, 0x20 | lvsl v7, 0, r4 | li r9, 0x30
consts: 0.159155 6.28319 1
status: -
callees: -

## `0x9809f6d8`
prologue: std r31, -8(r1) | lis r11, 0x124 | stfs f1, -0x50(r1) | lwz r10, -0x50(r1) | lis r9, -0x6800
consts: 0.159155 6.28319 1
status: -
callees: -

## `0x9809f898`
prologue: mflr r12 | bl 0x980618a8 | lis r11, 0x124 | stfs f1, -0xa0(r1) | lwz r10, -0xa0(r1)
consts: 0.159155 1 6.28319 2.48016e-05 3.14159 2.75573e-06
status: -
callees: 0x980618a8(read)

## `0x9809fad8`
prologue: VMX-6-p06(undecoded) | lis r11, -0x6800 | addi r10, r1, -0x10 | stfs f2, -0x10(r1) | lis r9, -0x6800
consts: 3.14159 1 2.48016e-05 2.75573e-06
status: -
callees: -

## `0x980af1b0`
prologue: mflr r12 | bl 0x980618cc | stwu r1, -0x80(r1) | mr r31, r3 | lis r11, -0x67fd
consts: 1
status: -
callees: 0x980618cc(read) 0x980af0d0(read) 0x980dbfc0(read) 0x980e81f8(read) 0x980dbfc0(read) 0x980b9768(read) 0x98061e30(read) 0x980618cc(read) 0x980af070 0x980af0d0(read) 0x980af140(read) 0x980a6b60(read) 0x980a6bd8(read) 0x980af378 0x980a6cd0(read) 0x980a6cd0(read) 0x980a6cd0(read) 0x980a6cd0(read)

## `0x980b0238`
prologue: std r31, -8(r1) | VMX-6-p06(undecoded) | addi r11, r3, 0xa8 | li r10, 0 | li r9, 1
consts: -
status: -
callees: 0x980aa270(read) 0x980a1e98

## `0x980b9da0`
prologue: mflr r12 | bl 0x980618c4 | stwu r1, -0xa0(r1) | mr r31, r3 | mr r29, r4
consts: 0.00392157 255
status: -
callees: 0x980618c4(read) 0x980b9c40(read) 0x980dbf98(read) 0x98063308(read) 0x98111bd8(read) 0x9813b4cc(read) 0x9813b4cc(read) 0x9813b4cc(read) 0x9813b4cc(read) 0x9813b4cc(read)

## `0x980ba720`
prologue: mflr r12 | bl 0x980618c4 | stwu r1, -0xe0(r1) | lwz r11, 0(r4) | mr r31, r3
consts: 0.00392157
status: -
callees: 0x980618c4(read) 0x980f0c40(read) 0x980b9d40(read) 0x980b99e8 0x980b9910(read) 0x980b98c8(read) 0x980b9838(read) 0x980dd920 0x980dd308(read) 0x980dd118(read) 0x980dbfc0(read) 0x980c1bd8(read) 0x980b0c20(read)

## `0x980c2760`
prologue: mflr r12 | bl 0x980618bc | lfs f0, 0(r3) | lis r11, -0x67fd | stfs f0, 0(r4)
consts: -
status: -
callees: 0x980618bc(read)

## `0x980c8aa0`
prologue: mflr r12 | bl 0x980618bc | addi r12, r1, -0x40 | bl 0x98063aac | stwu r1, -0x250(r1)
consts: 1 0.5 -1 -0.5
status: -
callees: 0x980618bc(read) 0x98063aac(read) 0x9810e5c0(read) 0x980e8168(read) 0x980e81b0(read) 0x980a5600(read) 0x980f0530(read) 0x980f05a8(read) 0x980f0638(read) 0x980f05a8(read) 0x980f0638(read) 0x980f0530(read) 0x980f0638(read) 0x980f05a8(read) 0x980f0638(read) 0x98063af8(read)

## `0x980d2fb0`
prologue: mflr r12 | bl 0x980618c4 | stwu r1, -0x180(r1) | mr r10, r4 | li r9, 1
consts: 1
status: -
callees: 0x980618c4(read) 0x980c10a0(read) 0x980aa2f0(read) 0x980b0c20(read) 0x980d1ae8(read) 0x980d1ae8(read) 0x980d1ae8(read) 0x980d1ae8(read) 0x980d1ae8(read) 0x980d1ae8(read) 0x980c2b38(read) 0x980a2f80(read) 0x980f0958(read) 0x980f0480(read) 0x980c3fd8 0x980aab60(read) 0x980aab60(read) 0x980618cc(read) 0x980ea128(read) 0x980cc8a0(read) 0x980ead60(read)

## `0x980d54f0`
prologue: mflr r12 | bl 0x980618c4 | stfd f30, -0x40(r1) | stfd f31, -0x38(r1) | stwu r1, -0x200(r1)
consts: -
status: -
callees: 0x980618c4(read) 0x980c3760(read) 0x980c3820(read) 0x980e8008(read) 0x980f0958(read) 0x980e7fe0(read) 0x980f27a8(read) 0x980d1e98(read) 0x980cc1e0(read) 0x980cbe68(read) 0x980f1710(read) 0x980e7fe0(read) 0x980e7fb8(read) 0x980e7ef0(read)

## `0x980e4ef0`
prologue: mflr r12 | bl 0x980618ac | stwu r1, -0xe0(r1) | VMX-6-p06(undecoded) | mr r31, r3
consts: 2 1 -1 -2 0.00392157
status: -
callees: 0x980618ac(read) 0x980f0a50(read)

## `0x980e5448`
prologue: mflr r12 | bl 0x980618a8 | stfd f31, -0x70(r1) | li r27, 0 | li r29, 1
consts: 0.5 255 0.00392157 1 0.0001
status: -
callees: 0x980618a8(read)

## `0x980f0480`
prologue: li r10, 8 | vcmpneb. v31, v0, v4 | li r11, 0x10 | vcmpneb. v30, v0, v5 | li r9, 0x20
consts: -
status: -
callees: -

## `0x980f0530`
prologue: addi r10, r1, 0x24 | stfs f2, 0x24(r1) | addi r8, r1, 0x2c | stfs f3, 0x2c(r1) | VMX-6-p06(undecoded)
consts: -
status: -
callees: -

## `0x980f05a8`
prologue: VMX-6-p06(undecoded) | addi r11, r1, 0x24 | addi r10, r1, 0x1c | stfs f1, 0x1c(r1) | lis r8, -0x6800
consts: 1
status: -
callees: -

## `0x980f0638`
prologue: li r9, 0x10 | vcmpneb. v31, v0, v5 | li r10, 0x20 | vcmpneb. v30, v0, v4 | li r11, 0x30
consts: -
status: -
callees: -

## `0x980f0760`
prologue: li r11, 8 | vcmpneb. v31, v0, v4 | VMX-6-p06(undecoded) | lis r10, -0x67fe | addi r10, r10, 0x5c70
consts: -
status: -
callees: -

## `0x980f07d8`
prologue: li r11, 0x10 | vcmpneb. v31, v0, v4 | VMX-6-p06(undecoded) | li r9, 0x20 | li r10, 0x30
consts: -
status: -
callees: -

## `0x980f0888`
prologue: li r8, 0xc | vcmpneb. v31, v0, v4 | li r9, 0x30 | vcmpneb. v30, v0, v5 | li r10, 0x20
consts: -
status: -
callees: -

## `0x980f0a50`
prologue: li r9, 0x10 | vcmpneb. v31, v0, v4 | li r10, 0x20 | li r11, 0x30 | li r8, 0x40
consts: -
status: -
callees: -

## `0x980f0ad8`
prologue: li r11, 0xc | vcmpneb. v31, v0, v5 | vcmpneb. v30, v0, v4 | VMX-6-p06(undecoded) | li r10, 0x10
consts: -
status: -
callees: -

## `0x980f0c40`
prologue: mflr r12 | stw r12, -8(r1) | std r30, -0x18(r1) | std r31, -0x10(r1) | stwu r1, -0x80(r1)
consts: 0.5
status: -
callees: 0x98058a48(read) 0x9809f6d8(read) 0x9803db10 0x9803faa8(read)

## `0x980f2ab8`
prologue: mflr r12 | stw r12, -8(r1) | std r31, -0x10(r1) | stwu r1, -0x60(r1) | mr r31, r3
consts: -
status: -
callees: 0x98111fb0(read)

## `0x98120c80`
prologue: vcmpequd v22, v30, v10 | VMX-5-p05(undecoded) | vcmpequd v20, v23, v11 | VMX-5-p05(undecoded) | VMX-5-p05(undecoded)
consts: -
status: -
callees: 0x98063adc

## `0x98125240`
prologue: mflr r12 | stw r12, -8(r1) | std r31, -0x10(r1) | stwu r1, -0xc0(r1) | mr r31, r3
consts: -
status: -
callees: 0x98062720(read) 0x98123188(read) 0x98124fb0(read) 0x98123638(read)

## `0x9812ae50`
prologue: mflr r12 | stw r12, -8(r1) | std r30, -0x18(r1) | std r31, -0x10(r1) | stwu r1, -0x70(r1)
consts: -
status: -
callees: -

## `0x9812b010`
prologue: mflr r12 | bl 0x980618cc | stwu r1, -0x80(r1) | mr r31, r7 | lfs f0, 0x24(r31)
consts: 4 0.117188
status: -
callees: 0x980618cc(read) 0x98061b40(read)

## `0x9812b440`
prologue: mflr r12 | bl 0x980618b0 | stwu r1, -0xd0(r1) | mr r26, r7 | lfs f0, 0x24(r26)
consts: 4 0.117188
status: -
callees: 0x980618b0(read) 0x98061b40(read)

## `0x9812b6d8`
prologue: mflr r12 | bl 0x98061894 | stwu r1, -0x100(r1) | mr r20, r7 | lfs f0, 0x24(r20)
consts: 4 0.117188
status: -
callees: 0x98061894(read) 0x98061b40(read)

## `0x9812bd00`
prologue: mflr r12 | bl 0x980618b0 | stwu r1, -0xd0(r1) | mr r28, r7 | lfs f0, 0x24(r28)
consts: 16 0.117188
status: -
callees: 0x980618b0(read) 0x98061b40(read)

## `0x981314b0`
prologue: mflr r12 | bl 0x980618a8 | addi r9, r3, 8 | lwz r10, 0(r3) | addi r8, r3, 0x1c
consts: 1.875 128
status: -
callees: 0x980618a8(read)

## `0x98132b10`
prologue: mflr r12 | bl 0x98061894 | addi r9, r3, 8 | lbz r4, 0xd(r3) | addi r8, r3, 0x1c
consts: 1.875 3.05176e-05
status: -
callees: 0x98061894(read)

## `0x98138ab8`
prologue: mflr r12 | bl 0x980618c4 | stwu r1, -0x90(r1) | lwz r10, 8(r3) | lbz r28, 0xd(r3)
consts: 4
status: -
callees: 0x980618c4(read) 0x981333d8(read)

## `0x98139210`
prologue: mflr r12 | bl 0x980618c4 | stwu r1, -0x90(r1) | lwz r10, 8(r3) | lbz r30, 0xd(r3)
consts: 4 16
status: -
callees: 0x980618c4(read) 0x98133a18(read) 0x980618a8(read) 0x98133d20 0x980618b8(read) 0x98134048

## `0x98139a18`
prologue: mflr r12 | stw r12, -8(r1) | std r30, -0x18(r1) | std r31, -0x10(r1) | stwu r1, -0x90(r1)
consts: 8
status: -
callees: 0x98134ff0(read)

## `0x98139c50`
prologue: mflr r12 | bl 0x980618cc | stwu r1, -0x90(r1) | lwz r11, 0x1c(r3) | lwz r10, 0x18(r3)
consts: 16
status: -
callees: 0x980618cc(read) 0x981358f0(read)

## `0x9813a290`
prologue: li r3, 2 | b 0x9813bcfc | mr r11, r3 | li r9, 4 | extsw r8, r4
consts: -
status: -
callees: -

## `0x9813b1c8`
prologue: mflr r12 | stw r12, -8(r1) | std r31, -0x10(r1) | stwu r1, -0x60(r1) | lis r11, -0x67e7
consts: -
status: -
callees: 0x980f15f0(read)
