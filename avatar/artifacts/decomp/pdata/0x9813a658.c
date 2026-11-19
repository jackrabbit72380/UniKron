
void FUN_9813a658(void)

{
  undefined4 *puVar1;
  int iVar2;
  int in_r0;
  longlong in_r6;
  longlong in_r7;
  ulonglong in_r8;
  ulonglong in_r9;
  ulonglong uVar3;
  ulonglong in_r10;
  ulonglong uVar4;
  longlong in_r11;
  byte in_cr6;
  undefined1 in_vs32 [16];
  undefined4 in_register_00010000;
  undefined4 in_ACC;
  undefined4 in_register_00010008;
  undefined4 in_vr0;
  
  if (!(bool)(in_cr6 >> 1 & 1)) {
    do {
      dataCacheBlockClearToZero((in_r10 & 0x1ffffff) * 0x80 + in_r11);
      in_r10 = in_r10 + 1;
    } while ((in_r10 & 0xffffffff) < (in_r8 & 0xffffffff));
  }
  uVar4 = 0;
  if ((in_r9 & 0xffffffff) != 0) {
    do {
      if ((uVar4 + 4 & 0xffffffff) < (in_r9 & 0xffffffff)) {
        dataCacheBlockClearToZero(in_r11 + 0x200);
      }
      iVar2 = (int)in_r11;
      puVar1 = (undefined4 *)(in_r0 + iVar2 & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      puVar1 = (undefined4 *)(iVar2 + 0x10U & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      puVar1 = (undefined4 *)(iVar2 + 0x20U & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      uVar4 = uVar4 + 1;
      puVar1 = (undefined4 *)(iVar2 + 0x30U & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      puVar1 = (undefined4 *)(iVar2 + 0x40U & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      puVar1 = (undefined4 *)(iVar2 + 0x50U & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      puVar1 = (undefined4 *)(iVar2 + 0x60U & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      puVar1 = (undefined4 *)(iVar2 + 0x70U & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      in_r11 = in_r11 + 0x80;
    } while ((uVar4 & 0xffffffff) < (in_r9 & 0xffffffff));
  }
  uVar4 = in_r7 + (in_r9 & 0x1ffffff) * -0x80;
  if (0xf < (uVar4 & 0xffffffff)) {
    uVar3 = (uVar4 & 0xffffffff) >> 4;
    do {
      puVar1 = (undefined4 *)(in_r0 + (int)in_r11 & 0xfffffff0);
      *puVar1 = in_register_00010000;
      puVar1[1] = in_ACC;
      puVar1[2] = in_register_00010008;
      puVar1[3] = in_vr0;
      uVar3 = uVar3 - 1;
      in_r11 = in_r6 + in_r11;
      uVar4 = uVar4 - 0x10;
    } while (uVar3 != 0);
  }
  storeVectorRightIndexed128(in_vs32,in_r11,uVar4);
  return;
}


