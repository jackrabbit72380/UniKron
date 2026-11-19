
void FUN_9811e978(undefined8 param_1,undefined8 param_2,double param_3,double param_4,
                 undefined8 param_5,undefined8 param_6,double param_7,double param_8,double param_9,
                 double param_10,undefined8 param_11,undefined8 param_12,double param_13,
                 int param_14,float *param_15,undefined8 param_16,float *param_17,uint param_18,
                 longlong param_19,ulonglong param_20,float *param_21)

{
  float fVar1;
  float fVar2;
  float fVar3;
  float fVar4;
  float *pfVar5;
  int in_r11;
  longlong unaff_r21;
  longlong unaff_r22;
  longlong unaff_r23;
  longlong unaff_r24;
  longlong unaff_r25;
  longlong unaff_r26;
  longlong unaff_r27;
  float *unaff_r28;
  double in_f0;
  double dVar6;
  double dVar7;
  double dVar8;
  double dVar9;
  
  while( true ) {
    fVar4 = *unaff_r28;
    param_19 = param_19 + -1;
    pfVar5 = param_15 + 8;
    param_18 = param_18 + 8;
    dVar8 = (double)*(float *)((int)unaff_r26 + in_r11);
    fVar1 = (float)(in_f0 * dVar8 + param_10);
    param_21[-1] = fVar1;
    dVar6 = (double)*(float *)((int)unaff_r27 + in_r11);
    fVar2 = (float)(in_f0 * dVar6 + param_9);
    *param_21 = fVar2;
    *param_17 = (float)(param_13 * (double)fVar1 + dVar8);
    param_15[3] = (float)(param_13 * (double)fVar2 + dVar6);
    dVar6 = (double)*(float *)((int)unaff_r25 + in_r11);
    fVar1 = (float)(in_f0 * dVar6 + param_8);
    param_21[1] = fVar1;
    param_15[4] = (float)(param_13 * (double)fVar1 + dVar6);
    dVar7 = (double)*(float *)((int)unaff_r24 + in_r11);
    fVar1 = (float)(in_f0 * dVar7 + param_7);
    param_21[2] = fVar1;
    dVar8 = (double)*(float *)((int)unaff_r23 + in_r11);
    fVar2 = (float)(in_f0 * dVar8 + param_4);
    param_21[3] = fVar2;
    dVar6 = (double)*(float *)((int)unaff_r22 + in_r11);
    fVar3 = (float)(in_f0 * dVar6 + param_3);
    param_21[4] = fVar3;
    dVar9 = (double)*(float *)((int)unaff_r21 + in_r11);
    fVar4 = (float)(in_f0 * dVar9 + (double)fVar4);
    param_21[5] = fVar4;
    param_15[5] = (float)(param_13 * (double)fVar1 + dVar7);
    fVar1 = (float)(param_13 * (double)fVar4 + dVar9);
    param_15[6] = (float)(param_13 * (double)fVar2 + dVar8);
    *unaff_r28 = (float)(param_13 * (double)fVar3 + dVar6);
    if (param_19 == 0) break;
    fVar2 = *pfVar5;
    *pfVar5 = fVar1;
    unaff_r27 = (param_20 + 8 & 0x7f) << 2;
    param_10 = (double)param_15[9];
    unaff_r26 = (param_20 + 7 & 0x7f) << 2;
    param_9 = (double)param_15[10];
    param_8 = (double)param_15[0xb];
    dVar6 = (double)*(float *)((param_18 & 0x7f) * 4 + in_r11);
    fVar1 = (float)(in_f0 * dVar6 + (double)fVar2);
    param_21[6] = fVar1;
    unaff_r25 = (param_20 + 9 & 0x7f) << 2;
    param_7 = (double)param_15[0xc];
    unaff_r24 = (param_20 + 10 & 0x7f) << 2;
    param_4 = (double)param_15[0xd];
    param_3 = (double)param_15[0xe];
    unaff_r22 = (param_20 + 0xc & 0x7f) << 2;
    param_17 = param_15 + 10;
    unaff_r23 = (param_20 + 0xb & 0x7f) << 2;
    unaff_r28 = param_15 + 0xf;
    param_15[9] = (float)(param_13 * (double)fVar1 + dVar6);
    unaff_r21 = (param_20 + 0xd & 0x7f) << 2;
    param_20 = param_20 + 8;
    param_15 = pfVar5;
    param_21 = param_21 + 8;
  }
  *(float *)(param_14 + 0xc) = fVar1;
  *pfVar5 = fVar1;
  *(undefined4 *)(param_14 + 0x10) = 0;
  FUN_98063b10();
  return;
}


