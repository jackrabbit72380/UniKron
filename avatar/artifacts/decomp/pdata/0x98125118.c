
void FUN_98125118(void)

{
  float fVar1;
  int in_r11;
  int unaff_r29;
  int unaff_r30;
  undefined4 *unaff_r31;
  double dVar2;
  double in_f30;
  double in_f31;
  undefined4 uStack00000054;
  
  unaff_r31[10] = in_r11 + 8;
  unaff_r31[0x12] = *(undefined4 *)(unaff_r30 + 0xc);
  fVar1 = DAT_9801e398;
  unaff_r31[0x10] = (float)((double)(longlong)*(int *)(unaff_r30 + 0x14) * in_f31);
  dVar2 = (double)(*(float *)(unaff_r30 + 0x18) * fVar1);
  if ((double)(uint)u_BackFromEnd_9802ffac._0_4_ <= dVar2) {
    dVar2 = (double)(float)((double)(uint)u_BackFromEnd_9802ffac._0_4_ - in_f30);
  }
  if (dVar2 <= in_f30) {
    dVar2 = in_f30;
  }
  *unaff_r31 = (int)(longlong)dVar2;
  unaff_r31[0x11] = (float)((double)(longlong)*(int *)(unaff_r30 + 0x1c) * in_f31);
  dVar2 = (double)(*(float *)(unaff_r30 + 0x20) * fVar1);
  if ((double)(uint)u_BackFromEnd_9802ffac._4_4_ <= dVar2) {
    dVar2 = (double)(float)((double)(uint)u_BackFromEnd_9802ffac._4_4_ - in_f30);
  }
  *(int *)((int)unaff_r31 + unaff_r29) = (int)(longlong)dVar2;
  uStack00000054 = (undefined4)(longlong)(*(float *)(unaff_r30 + 0x24) * DAT_98005284);
  unaff_r31[7] = uStack00000054;
  unaff_r31[6] = uStack00000054;
  unaff_r31[0x13] = *(undefined4 *)(unaff_r30 + 0x28);
  unaff_r31[0xd] = *(undefined4 *)(unaff_r30 + 0x2c);
  return;
}


