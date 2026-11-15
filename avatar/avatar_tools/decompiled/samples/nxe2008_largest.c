
/* WARNING: Control flow encountered bad instruction data */
/* WARNING: Removing unreachable block (ram,0x980de5a4) */

void FUN_980ded60(undefined4 param_1,undefined4 param_2,int param_3,int param_4,int *param_5,
                 int *param_6,int *param_7,undefined4 param_8)

{
  undefined1 uVar1;
  undefined1 uVar2;
  undefined2 uVar3;
  int iVar4;
  int iVar5;
  byte *pbVar6;
  undefined4 uVar7;
  int iVar8;
  byte *pbVar9;
  uint uVar10;
  ushort uVar12;
  int *piVar11;
  uint uVar13;
  int iVar14;
  uint *puVar15;
  undefined4 *puVar16;
  undefined4 *puVar17;
  undefined4 *puVar18;
  ushort *puVar19;
  undefined8 uVar20;
  uint local_a0 [40];
  
  uVar20 = FUN_98061894();
  puVar15 = (uint *)((ulonglong)uVar20 >> 0x20);
  *param_7 = 0;
  pbVar9 = (byte *)*param_5;
  *param_5 = (int)(pbVar9 + (*pbVar9 & 7) + 1);
  iVar14 = 0;
  *param_6 = (*param_6 - (*pbVar9 & 7)) + -1;
  if (((*pbVar9 & 7) != 0) && (uVar13 = 0, (uint)uVar20 != 0)) {
    do {
      iVar5 = FUN_980ddc98(pbVar9,uVar13);
      if (iVar5 != 0) {
        puVar16 = (undefined4 *)0x1;
        if ((*puVar15 & 1) != 0) {
          pbVar6 = (byte *)*param_5;
          if ((*pbVar6 & 0x80) == 0) {
            iVar5 = 1;
          }
          else {
            iVar5 = (*pbVar6 & 0xffffff7f) + 1;
          }
          *param_5 = (int)(pbVar6 + iVar5);
          if ((*pbVar6 & 0x80) == 0) {
            iVar5 = 1;
          }
          else {
            iVar5 = (*pbVar6 & 0xffffff7f) + 1;
          }
          *param_6 = *param_6 - iVar5;
          puVar16 = (undefined4 *)FUN_980ddcf0();
        }
        puVar17 = (undefined4 *)0x0;
        if (puVar16 != (undefined4 *)0x0) {
          puVar18 = (undefined4 *)(iVar14 * 0x10 + param_3 + 4);
          do {
            puVar19 = (ushort *)0x0;
            if (param_3 != 0) {
              *puVar18 = puVar15;
              puVar19 = (ushort *)(puVar18 + -1);
              puVar18[2] = param_4;
              *(short *)((int)puVar18 + -2) = (short)puVar17;
            }
            uVar10 = puVar15[5];
            if (uVar10 == 9) {
              uVar7 = (*(code *)puVar15[10])(local_a0);
              uVar3 = *(undefined2 *)*param_5;
              *param_5 = (int)((undefined2 *)*param_5 + 1);
              *param_6 = *param_6 + -2;
              if ((local_a0[0] != 0) && (puVar19 != (ushort *)0x0)) {
                *puVar19 = *puVar19 | 0x10;
                iVar5 = FUN_980debd8(param_8,uVar3);
                *(int *)(puVar19 + 4) = iVar5;
                if (iVar5 == 0) {
                  halt_baddata();
                }
              }
              local_a0[1] = 0;
              if (puVar19 == (ushort *)0x0) {
                iVar5 = 0;
              }
              else {
                iVar5 = *(int *)(puVar19 + 4) + 8;
              }
              iVar5 = FUN_980ded60(uVar7,local_a0[0],iVar5,param_4,param_5,param_6,local_a0 + 1,
                                   param_8);
              if (iVar5 < 0) {
                halt_baddata();
              }
              if (puVar19 != (ushort *)0x0) {
                uVar12 = *puVar19 | 4;
LAB_980defb4:
                *puVar19 = uVar12;
              }
            }
            else if (uVar10 == 10) {
              iVar5 = *(int *)*param_5;
              *param_5 = (int)((int *)*param_5 + 1);
              *param_6 = *param_6 + -4;
              if (puVar19 != (ushort *)0x0) {
                *(int *)(param_4 + 0x28) = *(int *)(param_4 + 0x28) + 1;
                *(int *)(puVar19 + 6) = param_4;
                *(int *)(puVar19 + 4) = *(int *)(param_4 + 0x24) + iVar5;
                uVar12 = *puVar19 & 0xffe8 | 0x12;
                goto LAB_980defb4;
              }
            }
            else {
              iVar5 = uVar10 - 1;
              piVar11 = (int *)0x0;
              switch(uVar10) {
              case 1:
                do {
                  puVar17 = (undefined4 *)((int)piVar11 + iVar5 + 8);
                  while( true ) {
                    piVar11 = (int *)puVar17[1];
                    iVar5 = 0;
                    if (piVar11 != (int *)0x0) {
                      iVar5 = *piVar11;
                    }
switchD_980deff0_caseD_4:
                    if (iVar5 <= (int)puVar18) break;
                    iVar8 = piVar11[1];
                    iVar5 = thunk_FUN_98061a04(*(undefined4 *)
                                                (*(int *)((int)piVar11 + iVar8 * (int)puVar18 + 0xc)
                                                + 0x10),puVar16);
                    if (iVar5 == 0) {
                      FUN_980dd678((int)piVar11 + iVar8 * (int)puVar18 + 8,local_a0);
                      iVar5 = thunk_FUN_98061a04(local_a0[0],param_7);
                      if (iVar5 == 0) {
                        iVar5 = FUN_980b0b08(*puVar17);
                        if (iVar5 == 0) {
                          halt_baddata();
                        }
                        if (iVar14 != 0) {
                          uVar1 = **(undefined1 **)puVar19;
                          *(undefined1 **)puVar19 = *(undefined1 **)puVar19 + 1;
                          *param_5 = *param_5 + -1;
                          uVar2 = **(undefined1 **)puVar19;
                          *(undefined1 **)puVar19 = *(undefined1 **)puVar19 + 1;
                          *param_5 = *param_5 + -1;
                          iVar5 = FUN_980ddd40(iVar5,local_a0,uVar1,uVar2);
                          if (iVar5 < 0) {
                            halt_baddata();
                          }
                          *(uint *)param_6[2] = local_a0[0];
                        }
                        iVar5 = 1;
                        if (iVar14 < 2) {
                          halt_baddata();
                        }
                        iVar8 = 4;
                        do {
                          iVar4 = (**(code **)(*(int *)(iVar8 + param_6[2] + -4) + 0x28))(local_a0);
                          uVar13 = (uint)**(byte **)puVar19;
                          *(byte **)puVar19 = *(byte **)puVar19 + 1;
                          *param_5 = *param_5 + -1;
                          if (local_a0[0] <= uVar13) {
                            halt_baddata();
                          }
                          iVar5 = iVar5 + 1;
                          *(uint *)(iVar8 + param_6[2]) = uVar13 * 0x30 + iVar4;
                          iVar8 = iVar8 + 4;
                        } while (iVar5 < iVar14);
                    /* WARNING: Bad instruction - Truncating control flow here */
                        halt_baddata();
                      }
                    }
                    puVar18 = (undefined4 *)((int)puVar18 + 1);
                  }
                  param_4 = param_4 + 1;
LAB_980de400:
                  piVar11 = (int *)puVar15[2];
                  iVar5 = 0;
                  if (piVar11 != (int *)0x0) {
switchD_980deff0_caseD_2:
                    iVar5 = *piVar11;
                  }
                  if (iVar5 <= param_4) {
                    halt_baddata();
                  }
                  puVar18 = (undefined4 *)0x0;
                  iVar5 = piVar11[1] * param_4;
                } while( true );
              case 2:
              case 3:
              case 6:
              case 7:
              case 8:
                goto switchD_980deff0_caseD_2;
              case 4:
                goto switchD_980deff0_caseD_4;
              case 5:
                param_4 = 0;
                puVar16 = (undefined4 *)&DAT_98001730;
                goto LAB_980de400;
              default:
                *param_5 = *param_5;
                *param_6 = *param_6;
              }
            }
            puVar17 = (undefined4 *)((int)puVar17 + 1);
            iVar14 = iVar14 + 1;
            puVar18 = puVar18 + 4;
            *param_7 = *param_7 + 1;
          } while (puVar17 < puVar16);
        }
      }
      uVar13 = uVar13 + 1;
      puVar15 = puVar15 + 0xc;
    } while (uVar13 < (uint)uVar20);
  }
                    /* WARNING: Bad instruction - Truncating control flow here */
  halt_baddata();
}

