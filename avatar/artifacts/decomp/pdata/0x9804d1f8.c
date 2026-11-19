
undefined8 FUN_9804d1f8(void)

{
  float fVar1;
  undefined4 *puVar2;
  float *pfVar3;
  int in_r0;
  undefined8 uVar4;
  ulonglong uVar5;
  int in_r10;
  int in_r11;
  int iVar6;
  int unaff_r27;
  longlong unaff_r28;
  int unaff_r30;
  int unaff_r31;
  float in_register_00010000;
  float in_ACC;
  float in_register_00010008;
  float in_vr0;
  undefined4 in_register_00010340;
  undefined4 in_register_00010360;
  undefined4 in_register_00010370;
  undefined4 in_register_00010374;
  undefined4 in_register_00010390;
  float in_register_000103a0;
  float in_register_000103c0;
  float in_register_000103c4;
  float in_register_000103c8;
  float in_vr60;
  undefined4 in_register_000103e0;
  undefined4 in_register_000103e4;
  undefined4 in_register_000103e8;
  undefined4 in_vr62;
  undefined4 uStack00000060;
  undefined4 uStack00000080;
  undefined4 uStack00000090;
  
  fVar1 = in_register_00010000 * in_register_000103c0 + in_ACC * in_register_000103c4 +
          in_register_00010008 * in_register_000103c8 + in_vr0 * in_vr60;
  puVar2 = (undefined4 *)(in_r0 + in_r11 & 0xfffffff0);
  *puVar2 = in_register_000103e0;
  puVar2[1] = in_register_000103e4;
  puVar2[2] = in_register_000103e8;
  puVar2[3] = in_vr62;
  puVar2 = (undefined4 *)(in_r0 + in_r10 & 0xfffffff0);
  *puVar2 = in_register_00010340;
  puVar2[1] = in_register_00010370;
  puVar2[2] = in_register_00010340;
  puVar2[3] = in_register_00010374;
  puVar2 = (undefined4 *)((uint)((int)&uStack00000080 + in_r0) & 0xfffffff0);
  *puVar2 = in_register_00010360;
  puVar2[1] = in_register_00010360;
  puVar2[2] = in_register_00010390;
  puVar2[3] = in_register_00010360;
  pfVar3 = (float *)((uint)((int)&uStack00000090 + in_r0) & 0xfffffff0);
  *pfVar3 = fVar1;
  pfVar3[1] = fVar1;
  pfVar3[2] = in_register_000103a0;
  pfVar3[3] = fVar1;
  if ((((unaff_r30 == 0x15) || (unaff_r30 == 0x13)) || (unaff_r30 == 0x14)) &&
     (uVar4 = FUN_980a22b8(), (int)uVar4 != 0)) {
    FUN_98042e90((int)unaff_r28,(undefined4 *)0x0,*(char *)(unaff_r31 + 0x408));
    *(undefined4 *)((int)unaff_r28 + 0x348d4) = DAT_98002454;
  }
  if (*(int **)(unaff_r31 + 0x1c) == (int *)0x0) {
    iVar6 = 0;
  }
  else {
    iVar6 = **(int **)(unaff_r31 + 0x1c);
  }
  if (iVar6 == 0x24) {
    uVar4 = FUN_98055570(*(int *)(unaff_r31 + 0xc));
    uVar5 = (ulonglong)((int)uVar4 == 2);
  }
  else if ((iVar6 < 0x2a) || (0x2b < iVar6)) {
    uVar5 = 0;
  }
  else {
    uVar5 = 1;
  }
  FUN_98042be0(unaff_r28,unaff_r27,(int)&uStack00000060,uVar5);
  return 0;
}


