
void FUN_9812ade8(longlong param_1,undefined8 param_2,longlong param_3)

{
  ulonglong uVar1;
  longlong in_r9;
  longlong in_r10;
  uint uVar2;
  ulonglong in_r11;
  int unaff_r31;
  double dVar3;
  
  uVar1 = (in_r11 & 0x7fffffff) << 1 | (in_r11 & 0xffffffff) >> 0x1f;
  trapWord(6,uVar1,0);
  uVar1 = (param_1 - in_r10 & 0xffffffffU) / uVar1;
  uVar2 = (uint)uVar1;
  if (*(uint *)(unaff_r31 + 4) <= uVar1) {
    uVar2 = *(uint *)(unaff_r31 + 4);
  }
  *(uint *)(unaff_r31 + 8) = uVar2;
  uVar1 = (param_3 - (ulonglong)*(uint *)(unaff_r31 + 0x14) & 0xffffffff) >> 2;
  uVar2 = *(uint *)(unaff_r31 + 0x18);
  if (uVar1 < *(uint *)(unaff_r31 + 0x18)) {
    uVar2 = (uint)uVar1;
  }
  *(uint *)(unaff_r31 + 0x1c) = uVar2;
  dVar3 = (double)FUN_98061b40(in_r9);
  *(float *)(unaff_r31 + 0x30) = (float)(dVar3 * DAT_9801e7b8);
  FUN_980618e0();
  return;
}


