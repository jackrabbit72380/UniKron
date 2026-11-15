
/* WARNING: Removing unreachable block (ram,0x0001406d7a3b) */
/* WARNING: Removing unreachable block (ram,0x0001406d9ce9) */
/* WARNING: Removing unreachable block (ram,0x0001406d9cef) */
/* WARNING: Removing unreachable block (ram,0x0001406d9cfd) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

ulonglong FUN_1406d71b0(longlong param_1,uint param_2,undefined8 param_3,longlong param_4,
                       longlong *param_5,undefined8 param_6,int param_7,int param_8)

{
  longlong *plVar1;
  uint *puVar2;
  float fVar3;
  float fVar4;
  float fVar5;
  byte bVar6;
  byte bVar7;
  ushort uVar8;
  short sVar9;
  longlong *plVar10;
  undefined8 *puVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  void *pvVar14;
  float fVar15;
  float fVar16;
  longlong lVar17;
  logger *plVar18;
  logger *plVar19;
  undefined8 uVar20;
  logger *plVar21;
  logger *extraout_RAX;
  logger *extraout_RAX_00;
  logger *plVar22;
  logger *extraout_RAX_01;
  byte *pbVar23;
  undefined1 (*pauVar24) [16];
  logger *plVar25;
  void *pvVar26;
  ulonglong uVar27;
  longlong *plVar28;
  int *piVar29;
  uint *puVar30;
  float *pfVar31;
  ulonglong uVar32;
  undefined8 *puVar33;
  undefined1 *puVar34;
  longlong lVar35;
  longlong lVar36;
  uint uVar37;
  ulonglong uVar38;
  longlong lVar39;
  ulonglong uVar40;
  uint uVar41;
  ulonglong uVar42;
  ulonglong uVar43;
  longlong lVar44;
  ulonglong uVar45;
  ushort uVar46;
  char cVar47;
  bool bVar48;
  undefined1 auVar49 [16];
  undefined1 auVar50 [16];
  float fVar51;
  undefined1 auVar52 [16];
  float fVar53;
  float fVar54;
  logger **in_stack_fffffffffffffb38;
  undefined4 uVar55;
  undefined1 local_488 [8];
  ulonglong local_480;
  ulonglong local_478;
  ulonglong local_470;
  ulonglong local_468;
  ulonglong local_460;
  ulonglong local_458;
  ulonglong local_450;
  ulonglong local_448;
  float *local_440;
  longlong local_438;
  longlong local_430;
  logger *local_428;
  logger *local_420;
  logger *local_418;
  undefined8 uStack_410;
  undefined8 local_408;
  undefined8 uStack_400;
  undefined8 local_3f8;
  undefined8 uStack_3f0;
  undefined8 local_3e8;
  undefined8 uStack_3e0;
  longlong local_3d8;
  longlong *plStack_3d0;
  undefined8 local_3c8;
  undefined8 uStack_3c0;
  undefined1 local_3b8 [16];
  undefined1 local_3a8 [16];
  undefined1 local_398 [16];
  uint local_388;
  uint local_384;
  int local_380;
  uint local_37c;
  ulonglong local_378;
  float *local_370;
  longlong local_368;
  undefined8 uStack_360;
  undefined8 local_358;
  undefined8 uStack_350;
  uint local_33c;
  undefined8 *local_338;
  undefined8 *local_330;
  longlong local_328;
  longlong *plStack_320;
  logger *local_318;
  logger *plStack_310;
  longlong local_308;
  longlong *plStack_300;
  undefined8 local_2f8;
  longlong *plStack_2f0;
  undefined8 local_2e8;
  longlong *plStack_2e0;
  undefined8 local_2d8;
  longlong *plStack_2d0;
  undefined8 local_2c8;
  longlong *plStack_2c0;
  undefined8 local_2b0;
  undefined1 local_2a8 [16];
  undefined8 *local_298;
  undefined8 *local_290;
  undefined8 local_288;
  undefined8 uStack_280;
  undefined1 local_278 [16];
  longlong local_268;
  longlong *plStack_260;
  longlong local_258;
  longlong *plStack_250;
  longlong local_248;
  longlong *plStack_240;
  longlong local_238;
  longlong *plStack_230;
  undefined1 local_228 [8];
  longlong lStack_220;
  undefined1 local_218 [16];
  undefined1 local_208 [16];
  uint *local_1f8;
  uint *puStack_1f0;
  uint *local_1e8;
  undefined *local_1d8;
  undefined8 local_1d0;
  logger *local_1c8;
  logger *plStack_1c0;
  logger *local_1b8;
  undefined1 local_1a8 [16];
  undefined1 local_198 [16];
  longlong *local_188;
  longlong *plStack_180;
  logger *local_178;
  undefined8 local_170;
  uint local_168;
  uint local_158;
  uint local_148;
  uint local_138;
  uint local_128;
  uint local_118;
  uint local_108;
  logger *local_f8;
  longlong local_f0;
  undefined8 local_e8;
  undefined8 uStack_e0;
  undefined4 local_d8;
  ulonglong local_d0;
  logger *local_c8;
  longlong *plStack_c0;
  longlong local_b8;
  uint local_ac;
  undefined1 local_a8 [16];
  undefined8 *local_98;
  ulonglong local_90;
  undefined8 local_80;
  
  local_80 = 0xfffffffffffffffe;
  local_ac = (uint)(param_8 == 0);
  local_1a8._8_8_ = 0xe0b29ca109f1c8c1;
  uStack_280 = (longlong *)0xe0b29ca109f1c8c1;
  cVar47 = '\0';
  if (*(int *)(param_1 + 0x120) == 0x2000000) {
    if (*(short *)(param_1 + 0x126) == 0x100 && *(short *)(param_1 + 0x124) == 0) {
      cVar47 = *(longlong *)(param_1 + 0x128) == -0x1f4d635ef60e373f;
    }
    else if (*(short *)(param_1 + 0x124) == 0 && *(short *)(param_1 + 0x126) == 0x200) {
      uVar43 = *(ulonglong *)(param_1 + 0x128);
      uVar43 = uVar43 >> 0x38 | (uVar43 & 0xff000000000000) >> 0x28 |
               (uVar43 & 0xff0000000000) >> 0x18 | (uVar43 & 0xff00000000) >> 8 |
               (uVar43 & 0xff000000) << 8 | (uVar43 & 0xff0000) << 0x18 | (uVar43 & 0xff00) << 0x28
               | uVar43 << 0x38;
      cVar47 = (0xc1c8f109a19cb2e0 < uVar43 == uVar43 < 0xc1c8f109a19cb2e0) * '\x02';
    }
  }
  local_f0 = param_4;
  local_b8 = param_1;
  FUN_1406e9cc0(&local_328,param_7);
  lVar35 = local_b8;
  if (local_328 == 0) {
    if ((*(int *)(*(longlong *)((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8) +
                 0x9c) < DAT_140809d78) && (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
      rex::RegisterLogCategory((char *)&DAT_140809d74);
      _Init_thread_footer(&DAT_140809d78);
    }
    plVar18 = rex::GetLoggerRaw(DAT_140809d74);
    if ((plVar18 != (logger *)0x0) && (*(int *)(plVar18 + 0x40) < 4)) {
      local_288 = (logger *)0x14078098c;
      uStack_280 = (longlong *)0x2a;
      local_1a8._8_4_ = 0x315;
      local_1a8._0_8_ =
           "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
      ;
      local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
      FUN_140621c50(plVar18,local_1a8,3,&local_288,&param_7);
    }
LAB_1406d748e:
    uVar43 = 0;
    goto joined_r0x0001406d749a;
  }
  if (param_7 == 2) {
    if (plStack_320 != (longlong *)0x0) {
      LOCK();
      *(int *)(plStack_320 + 1) = (int)plStack_320[1] + 1;
      UNLOCK();
    }
    uVar41 = *(uint *)(local_b8 + 4);
    uVar37 = *(uint *)(local_b8 + 8);
    FUN_1406ea700(cVar47,uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 |
                         uVar41 << 0x18,
                  uVar37 >> 0x18 | (uVar37 & 0xff0000) >> 8 | (uVar37 & 0xff00) << 8 |
                  uVar37 << 0x18);
  }
  else {
    if (param_7 != 1) {
      if ((*(int *)(*(longlong *)((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8) +
                   0x9c) < DAT_140809d78) && (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
        rex::RegisterLogCategory((char *)&DAT_140809d74);
        _Init_thread_footer(&DAT_140809d78);
      }
      plVar18 = rex::GetLoggerRaw(DAT_140809d74);
      if ((plVar18 != (logger *)0x0) && (*(int *)(plVar18 + 0x40) < 4)) {
        local_288 = (logger *)0x140780a4a;
        uStack_280 = (longlong *)0x23;
        local_1a8._8_4_ = 800;
        local_1a8._0_8_ =
             "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
        ;
        local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
        FUN_140621c50(plVar18,local_1a8,3,&local_288,&param_7);
      }
      goto LAB_1406d748e;
    }
    if (plStack_320 != (longlong *)0x0) {
      LOCK();
      *(int *)(plStack_320 + 1) = (int)plStack_320[1] + 1;
      UNLOCK();
    }
    uVar41 = *(uint *)(local_b8 + 4);
    uVar37 = *(uint *)(local_b8 + 8);
    FUN_1406e9d10(cVar47,uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 |
                         uVar41 << 0x18,
                  uVar37 >> 0x18 | (uVar37 & 0xff0000) >> 8 | (uVar37 & 0xff00) << 8 |
                  uVar37 << 0x18);
  }
  uVar41 = param_2 & 0xffffefff;
  local_f8 = (logger *)(lVar35 + 0x120);
  local_1f8 = (uint *)0x0;
  puStack_1f0 = (uint *)0x0;
  local_1e8 = (uint *)0x0;
  local_33c = param_2;
  for (uVar43 = 0; uVar43 < 3; uVar43 = uVar43 + 1) {
    lVar17 = uVar43 * 0x10;
    pauVar24 = (undefined1 (*) [16])(lVar35 + 0xc + lVar17);
    local_1a8 = ZEXT816(0);
    if ((((*(int *)(lVar35 + 0xc + lVar17) != 0) || (*(short *)(lVar35 + 0x10 + lVar17) != 0)) ||
        (*(short *)(lVar35 + 0x12 + lVar17) != 0)) || (*(longlong *)(*pauVar24 + 8) != 0)) {
      FUN_1406ddd60(local_a8,local_f0);
      if ((logger *)local_a8._0_8_ == (logger *)0x0) {
        if ((*(int *)(*(longlong *)((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8)
                     + 0x9c) < DAT_140809d78) &&
           (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
          rex::RegisterLogCategory((char *)&DAT_140809d74);
          _Init_thread_footer(&DAT_140809d78);
        }
        plVar18 = rex::GetLoggerRaw(DAT_140809d74);
        auVar49 = local_198;
        if ((plVar18 != (logger *)0x0) && (*(int *)(plVar18 + 0x40) < 5)) {
          uVar37 = *(uint *)*pauVar24;
          local_1a8._0_4_ =
               uVar37 >> 0x18 | (uVar37 & 0xff0000) >> 8 | (uVar37 & 0xff00) << 8 | uVar37 << 0x18;
          local_198._2_2_ = 0;
          local_198._0_2_ = *(ushort *)(*pauVar24 + 4) << 8 | *(ushort *)(*pauVar24 + 4) >> 8;
          local_198._4_12_ = auVar49._4_12_;
          local_188 = (longlong *)
                      CONCAT44(local_188._4_4_,
                               (uint)(ushort)(*(ushort *)(*pauVar24 + 6) << 8 |
                                             *(ushort *)(*pauVar24 + 6) >> 8));
          local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)(*pauVar24)[8]);
          local_168 = (uint)(byte)(*pauVar24)[9];
          local_158 = (uint)(byte)(*pauVar24)[10];
          local_148 = (uint)(byte)(*pauVar24)[0xb];
          local_138 = (uint)(byte)(*pauVar24)[0xc];
          local_128 = (uint)(byte)(*pauVar24)[0xd];
          local_118 = (uint)(byte)(*pauVar24)[0xe];
          local_108 = (uint)(byte)(*pauVar24)[0xf];
          local_318 = (logger *)0x22222222222;
          plStack_310 = (logger *)local_1a8;
          lStack_220 = 0x46;
          local_228 = (undefined1  [8])&DAT_140776223;
          FUN_140729480(&local_288,local_228,&local_318);
          local_318 = (logger *)0x140780a6e;
          plStack_310 = (logger *)0x25;
          local_1a8._8_4_ = 0x32f;
          local_1a8._0_8_ =
               "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
          ;
          local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
          in_stack_fffffffffffffb38 = (logger **)&local_288;
          FUN_140612b30(plVar18,local_1a8,4,&local_318,in_stack_fffffffffffffb38);
          if (0xf < (ulonglong)local_278._8_8_) {
            plVar18 = local_288;
            if ((0xfff < local_278._8_8_ + 1) &&
               (plVar18 = *(logger **)(local_288 + -8),
               (logger *)0x1f < local_288 + (-8 - (longlong)plVar18))) {
                    /* WARNING: Subroutine does not return */
              _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
            }
            free(plVar18);
          }
        }
      }
      else {
        local_1a8 = *pauVar24;
        if (local_a8._8_8_ == 0) {
          local_198._8_8_ = 0;
          local_198._0_8_ = local_a8._0_8_;
        }
        else {
          LOCK();
          *(int *)(local_a8._8_8_ + 8) = *(int *)(local_a8._8_8_ + 8) + 1;
          UNLOCK();
          local_198 = local_a8;
        }
        if (puStack_1f0 == local_1e8) {
          FUN_1406e1250(&local_1f8);
          uVar20 = local_198._8_8_;
          if ((longlong *)local_198._8_8_ != (longlong *)0x0) {
            LOCK();
            plVar28 = (longlong *)(local_198._8_8_ + 8);
            *(int *)plVar28 = (int)*plVar28 + -1;
            UNLOCK();
            if ((int)*plVar28 == 0) {
              (*(code *)**(undefined8 **)local_198._8_8_)(local_198._8_8_);
              LOCK();
              piVar29 = (int *)(uVar20 + 0xc);
              *piVar29 = *piVar29 + -1;
              UNLOCK();
              if (*piVar29 == 0) {
                (**(code **)(*(longlong *)uVar20 + 8))(uVar20);
              }
            }
          }
        }
        else {
          *(undefined8 *)puStack_1f0 = local_1a8._0_8_;
          *(undefined8 *)(puStack_1f0 + 2) = local_1a8._8_8_;
          puStack_1f0[4] = 0;
          puStack_1f0[5] = 0;
          puStack_1f0[6] = 0;
          puStack_1f0[7] = 0;
          *(undefined8 *)(puStack_1f0 + 4) = local_198._0_8_;
          *(undefined8 *)(puStack_1f0 + 6) = local_198._8_8_;
          puStack_1f0 = puStack_1f0 + 8;
        }
      }
      uVar20 = local_a8._8_8_;
      if ((longlong *)local_a8._8_8_ != (longlong *)0x0) {
        LOCK();
        plVar28 = (longlong *)(local_a8._8_8_ + 8);
        *(int *)plVar28 = (int)*plVar28 + -1;
        UNLOCK();
        if ((int)*plVar28 == 0) {
          (*(code *)**(undefined8 **)local_a8._8_8_)(local_a8._8_8_);
          LOCK();
          piVar29 = (int *)(uVar20 + 0xc);
          *piVar29 = *piVar29 + -1;
          UNLOCK();
          if (*piVar29 == 0) {
            (**(code **)(*(longlong *)uVar20 + 8))(uVar20);
          }
        }
      }
    }
  }
  local_2a8 = (undefined1  [16])0x0;
  local_298 = (undefined8 *)0x0;
  local_1a8 = (undefined1  [16])0x0;
  if (((((*(int *)(local_b8 + 0x120) != 0) || (*(short *)(local_b8 + 0x124) != 0)) ||
       (*(short *)(local_b8 + 0x126) != 0)) || (*(longlong *)(local_b8 + 0x128) != 0)) &&
     ((uVar41 & (ushort)(*(ushort *)(local_b8 + 0x130) << 8 | *(ushort *)(local_b8 + 0x130) >> 8))
      != 0)) {
    FUN_1406e16c0(local_2a8,0);
  }
  local_1a8 = (undefined1  [16])0x0;
  if ((((*(int *)(local_b8 + 0x140) != 0) || (*(short *)(local_b8 + 0x144) != 0)) ||
      ((*(short *)(local_b8 + 0x146) != 0 || (*(longlong *)(local_b8 + 0x148) != 0)))) &&
     ((uVar41 & (ushort)(*(ushort *)(local_b8 + 0x150) << 8 | *(ushort *)(local_b8 + 0x150) >> 8))
      != 0)) {
    if ((undefined8 *)local_2a8._8_8_ == local_298) {
      FUN_1406e16c0(local_2a8);
    }
    else {
      uVar20 = *(undefined8 *)(local_b8 + 0x140);
      uVar12 = *(undefined8 *)(local_b8 + 0x148);
      *(undefined1 (*) [16])(local_2a8._8_8_ + 0x10) = *(undefined1 (*) [16])(local_b8 + 0x150);
      *(undefined8 *)local_2a8._8_8_ = uVar20;
      *(undefined8 *)(local_2a8._8_8_ + 8) = uVar12;
      local_2a8._8_8_ = (undefined8 *)(local_2a8._8_8_ + 0x20);
    }
  }
  lVar35 = 0x160;
  do {
    while( true ) {
      piVar29 = (int *)(local_b8 + lVar35);
      local_1a8 = ZEXT816(0);
      if ((((*piVar29 != 0) || ((short)piVar29[1] != 0)) ||
          ((*(short *)((longlong)piVar29 + 6) != 0 ||
           (plVar18 = (logger *)0x0, *(longlong *)(piVar29 + 2) != 0)))) &&
         (uVar46 = *(ushort *)(piVar29 + 4) << 8 | *(ushort *)(piVar29 + 4) >> 8,
         plVar18 = (logger *)(ulonglong)uVar46, (uVar41 & uVar46) != 0)) break;
LAB_1406d7a49:
      lVar35 = lVar35 + 0x20;
      if (lVar35 == 0x300) goto LAB_1406d7ae0;
    }
    if ((undefined8 *)local_2a8._8_8_ == local_298) {
      plVar18 = (logger *)FUN_1406e16c0(local_2a8);
      goto LAB_1406d7a49;
    }
    uVar20 = *(undefined8 *)piVar29;
    uVar12 = *(undefined8 *)(piVar29 + 2);
    *(undefined1 (*) [16])(local_2a8._8_8_ + 0x10) = *(undefined1 (*) [16])(piVar29 + 4);
    *(undefined8 *)local_2a8._8_8_ = uVar20;
    *(undefined8 *)(local_2a8._8_8_ + 8) = uVar12;
    local_2a8._8_8_ = (undefined8 *)(local_2a8._8_8_ + 0x20);
    lVar35 = lVar35 + 0x20;
  } while (lVar35 != 0x300);
LAB_1406d7ae0:
  uVar20 = local_2a8._8_8_;
  if (local_2a8._0_8_ != local_2a8._8_8_) {
    plVar18 = (logger *)(local_2a8._0_8_ + 8);
    do {
      local_1a8 = (undefined1  [16])0x0;
      if (((((*(uint *)(plVar18 + -8) != 0) || (*(short *)(plVar18 + -4) != 0)) ||
           (*(short *)(plVar18 + -2) != 0)) || (*(longlong *)plVar18 != 0)) &&
         (((byte)plVar18[9] & 0x40) != 0)) {
        plVar19 = (logger *)local_2a8._0_8_;
        if (local_f0 != 0) goto LAB_1406d7b74;
        goto LAB_1406d7c68;
      }
      plVar19 = plVar18 + 0x20;
      plVar25 = plVar18 + 0x18;
      plVar18 = plVar19;
    } while (plVar25 != (logger *)local_2a8._8_8_);
  }
  plVar19 = (logger *)local_2a8._8_8_;
  if (local_f0 != 0) goto LAB_1406d7c82;
LAB_1406d7c68:
  local_2b0 = local_2b0 & 0xffffffff00000000;
  plVar18 = (logger *)local_2a8._8_8_;
LAB_1406d7cb9:
  local_1c8 = (logger *)0x0;
  plStack_1c0 = (logger *)0x0;
  local_1b8 = (logger *)0x0;
  local_f8 = (logger *)(local_b8 + 0x300);
  local_290 = (undefined8 *)(local_b8 + 800);
  local_330 = (undefined8 *)(local_b8 + 0x340);
  local_338 = (undefined8 *)(local_b8 + 0x360);
  for (plVar19 = (logger *)local_2a8._0_8_; plVar19 != plVar18; plVar19 = plVar19 + 0x20) {
    while( true ) {
      local_c8 = (logger *)0x0;
      local_1d8 = (undefined *)0x0;
      local_318 = (logger *)0x0;
      plStack_310 = (logger *)0x0;
      local_308 = 0;
      in_stack_fffffffffffffb38 = &local_318;
      cVar47 = FUN_1406dde80(local_f0,plVar19,&local_c8,&local_1d8,in_stack_fffffffffffffb38);
      if (((cVar47 != '\0') && (lVar35 = FUN_1406eb780(local_c8,local_1d8), lVar35 != 0)) &&
         (lVar35 = FUN_1406eb780(local_c8,local_1d8), lVar35 == 0)) break;
      if (local_318 != (logger *)0x0) {
        plVar25 = local_318;
        if ((0xfff < (ulonglong)(local_308 - (longlong)local_318)) &&
           (plVar25 = *(logger **)(local_318 + -8),
           (logger *)0x1f < local_318 + (-8 - (longlong)plVar25))) {
                    /* WARNING: Subroutine does not return */
          _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
        }
        free(plVar25);
      }
      FUN_1406de5c0(&local_e8,local_f0);
      if ((longlong *)CONCAT44(local_e8._4_4_,(undefined4)local_e8) == (longlong *)0x0) {
        if ((*(int *)(*(longlong *)((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8)
                     + 0x9c) < DAT_140809d78) &&
           (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
          rex::RegisterLogCategory((char *)&DAT_140809d74);
          _Init_thread_footer(&DAT_140809d78);
        }
        plVar25 = rex::GetLoggerRaw(DAT_140809d74);
        auVar49 = local_198;
        if ((plVar25 != (logger *)0x0) && (*(int *)(plVar25 + 0x40) < 5)) {
          uVar41 = *(uint *)plVar19;
          local_1a8._0_4_ =
               uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
          local_198._2_2_ = 0;
          local_198._0_2_ = *(ushort *)(plVar19 + 4) << 8 | *(ushort *)(plVar19 + 4) >> 8;
          local_198._4_12_ = auVar49._4_12_;
          local_188 = (longlong *)
                      CONCAT44(local_188._4_4_,
                               (uint)(ushort)(*(ushort *)(plVar19 + 6) << 8 |
                                             *(ushort *)(plVar19 + 6) >> 8));
          local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)plVar19[8]);
          local_168 = (uint)(byte)plVar19[9];
          local_158 = (uint)(byte)plVar19[10];
          local_148 = (uint)(byte)plVar19[0xb];
          local_138 = (uint)(byte)plVar19[0xc];
          local_128 = (uint)(byte)plVar19[0xd];
          local_118 = (uint)(byte)plVar19[0xe];
          local_108 = (uint)(byte)plVar19[0xf];
          local_318 = (logger *)0x22222222222;
          plStack_310 = (logger *)local_1a8;
          lStack_220 = 0x46;
          local_228 = (undefined1  [8])&DAT_140776223;
          FUN_140729480(&local_288,local_228,&local_318);
          local_318 = (logger *)0x140780b3a;
          plStack_310 = (logger *)0x37;
          local_1a8._8_4_ = 0x3ce;
          local_1a8._0_8_ =
               "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
          ;
          local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
          in_stack_fffffffffffffb38 = (logger **)&local_288;
          FUN_140612b30(plVar25,local_1a8,4,&local_318,in_stack_fffffffffffffb38);
          if (0xf < (ulonglong)local_278._8_8_) {
            plVar25 = local_288;
            if ((0xfff < local_278._8_8_ + 1) &&
               (plVar25 = *(logger **)(local_288 + -8),
               (logger *)0x1f < local_288 + (-8 - (longlong)plVar25))) {
                    /* WARNING: Subroutine does not return */
              _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
            }
            free(plVar25);
          }
        }
        local_278 = ZEXT816(0);
        local_288 = (logger *)0x0;
        uStack_280 = (longlong *)0x0;
        sVar9 = *(short *)(plVar19 + 0x10);
        plVar25 = local_f8;
        if ((((*(short *)(local_b8 + 0x310) == sVar9) ||
             (plVar25 = (logger *)local_290, *(short *)(local_b8 + 0x330) == sVar9)) ||
            (plVar25 = (logger *)local_330, *(short *)(local_b8 + 0x350) == sVar9)) ||
           (plVar25 = (logger *)local_338, *(short *)(local_b8 + 0x370) == sVar9)) {
          FUN_1406de5c0(local_1a8,local_f0);
          auVar49 = local_1a8;
          local_1a8 = ZEXT816(0);
          plVar28 = (longlong *)CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
          local_e8._0_4_ = auVar49._0_4_;
          local_e8._4_4_ = auVar49._4_4_;
          uStack_e0._0_4_ = auVar49._8_4_;
          uStack_e0._4_4_ = auVar49._12_4_;
          if (plVar28 != (longlong *)0x0) {
            LOCK();
            plVar10 = plVar28 + 1;
            *(int *)plVar10 = (int)*plVar10 + -1;
            UNLOCK();
            if ((int)*plVar10 == 0) {
              (**(code **)*plVar28)(plVar28);
              LOCK();
              piVar29 = (int *)((longlong)plVar28 + 0xc);
              *piVar29 = *piVar29 + -1;
              UNLOCK();
              if (*piVar29 == 0) {
                (**(code **)(*plVar28 + 8))(plVar28);
              }
            }
            uVar20 = local_1a8._8_8_;
            if ((longlong *)local_1a8._8_8_ != (longlong *)0x0) {
              LOCK();
              plVar28 = (longlong *)(local_1a8._8_8_ + 8);
              *(int *)plVar28 = (int)*plVar28 + -1;
              UNLOCK();
              if ((int)*plVar28 == 0) {
                (*(code *)**(undefined8 **)local_1a8._8_8_)(local_1a8._8_8_);
                LOCK();
                piVar29 = (int *)(uVar20 + 0xc);
                *piVar29 = *piVar29 + -1;
                UNLOCK();
                if (*piVar29 == 0) {
                  (**(code **)(*(longlong *)uVar20 + 8))(uVar20);
                }
              }
            }
          }
          local_288 = *(logger **)plVar25;
          uStack_280 = *(longlong **)((longlong)plVar25 + 8);
          local_278 = *(undefined1 (*) [16])((longlong)plVar25 + 0x10);
        }
        if ((longlong *)CONCAT44(local_e8._4_4_,(undefined4)local_e8) == (longlong *)0x0) {
          local_1a8 = ZEXT816(0);
          uVar41 = (uint)local_288;
          uVar46 = local_288._4_2_;
          uVar8 = local_288._6_2_;
          if (((local_288._4_2_ != 0 || (uint)local_288 != 0) || local_288._6_2_ != 0) ||
             (uStack_280 != (longlong *)0x0)) {
            if ((*(int *)(*(longlong *)
                           ((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8) + 0x9c)
                 < DAT_140809d78) && (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
              rex::RegisterLogCategory((char *)&DAT_140809d74);
              _Init_thread_footer(&DAT_140809d78);
            }
            plVar25 = rex::GetLoggerRaw(DAT_140809d74);
            auVar49 = local_198;
            if ((plVar25 != (logger *)0x0) && (*(int *)(plVar25 + 0x40) < 5)) {
              local_1a8._0_4_ =
                   uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 |
                   uVar41 << 0x18;
              local_198._2_2_ = 0;
              local_198._0_2_ = uVar46 << 8 | uVar46 >> 8;
              local_198._4_12_ = auVar49._4_12_;
              local_188 = (longlong *)
                          CONCAT44(local_188._4_4_,(uint)(ushort)(uVar8 << 8 | uVar8 >> 8));
              local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)uStack_280);
              local_168 = (uint)uStack_280._1_1_;
              local_158 = (uint)uStack_280._2_1_;
              local_148 = (uint)uStack_280._3_1_;
              local_138 = (uint)uStack_280._4_1_;
              local_128 = (uint)uStack_280._5_1_;
              local_118 = (uint)uStack_280._6_1_;
              local_108 = (uint)uStack_280._7_1_;
              lStack_220 = (longlong)local_1a8;
              local_228 = (undefined1  [8])0x22222222222;
              local_a8._8_8_ = 0x46;
              local_a8._0_8_ = &DAT_140776223;
              FUN_140729480(&local_318,local_a8,local_228);
              lStack_220 = 0x28;
              local_228 = (undefined1  [8])"Failed to load fallback avatar asset {}!";
              local_1a8._8_4_ = 0x3dc;
              local_1a8._0_8_ =
                   "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
              ;
              local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
              in_stack_fffffffffffffb38 = &local_318;
              FUN_140612b30(plVar25,local_1a8,4,local_228,in_stack_fffffffffffffb38);
              if ((longlong *)0xf < plStack_300) {
                plVar25 = local_318;
                if ((0xfff < (longlong)plStack_300 + 1U) &&
                   (plVar25 = *(logger **)(local_318 + -8),
                   (logger *)0x1f < local_318 + (-8 - (longlong)plVar25))) {
                    /* WARNING: Subroutine does not return */
                  _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
                }
                free(plVar25);
              }
            }
          }
        }
        else {
          local_198 = local_278;
          local_1a8._8_8_ = uStack_280;
          local_1a8._0_8_ = local_288;
          if (CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) == 0) {
            local_188 = (longlong *)CONCAT44(local_e8._4_4_,(undefined4)local_e8);
            plStack_180 = (longlong *)0x0;
          }
          else {
            LOCK();
            piVar29 = (int *)(CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) + 8);
            *piVar29 = *piVar29 + 1;
            UNLOCK();
            local_188 = (longlong *)CONCAT44(local_e8._4_4_,(undefined4)local_e8);
            plStack_180 = (longlong *)CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
          }
          if (plStack_1c0 == local_1b8) {
            FUN_1406e2c50(&local_1c8);
            plVar28 = plStack_180;
            if (plStack_180 != (longlong *)0x0) {
              LOCK();
              plVar10 = plStack_180 + 1;
              *(int *)plVar10 = (int)*plVar10 + -1;
              UNLOCK();
              if ((int)*plVar10 == 0) {
                (**(code **)*plStack_180)(plStack_180);
                LOCK();
                piVar29 = (int *)((longlong)plVar28 + 0xc);
                *piVar29 = *piVar29 + -1;
                UNLOCK();
                if (*piVar29 == 0) {
                  (**(code **)(*plVar28 + 8))(plVar28);
                }
              }
            }
          }
          else {
            *(undefined1 (*) [16])(plStack_1c0 + 0x10) = local_278;
            *(logger **)plStack_1c0 = local_288;
            *(longlong **)(plStack_1c0 + 8) = uStack_280;
            *(undefined8 *)(plStack_1c0 + 0x20) = 0;
            *(undefined8 *)(plStack_1c0 + 0x28) = 0;
            *(longlong **)(plStack_1c0 + 0x20) = local_188;
            *(longlong **)(plStack_1c0 + 0x28) = plStack_180;
            plStack_1c0 = plStack_1c0 + 0x30;
          }
        }
      }
      else {
        local_1a8 = *(undefined1 (*) [16])plVar19;
        local_198 = *(undefined1 (*) [16])(plVar19 + 0x10);
        if (CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) == 0) {
          local_188 = (longlong *)CONCAT44(local_e8._4_4_,(undefined4)local_e8);
          plStack_180 = (longlong *)0x0;
        }
        else {
          LOCK();
          piVar29 = (int *)(CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) + 8);
          *piVar29 = *piVar29 + 1;
          UNLOCK();
          local_188 = (longlong *)CONCAT44(local_e8._4_4_,(undefined4)local_e8);
          plStack_180 = (longlong *)CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
        }
        if (plStack_1c0 == local_1b8) {
          FUN_1406e2c50(&local_1c8);
          plVar28 = plStack_180;
          if (plStack_180 != (longlong *)0x0) {
            LOCK();
            plVar10 = plStack_180 + 1;
            *(int *)plVar10 = (int)*plVar10 + -1;
            UNLOCK();
            if ((int)*plVar10 == 0) {
              (**(code **)*plStack_180)(plStack_180);
              LOCK();
              piVar29 = (int *)((longlong)plVar28 + 0xc);
              *piVar29 = *piVar29 + -1;
              UNLOCK();
              if (*piVar29 == 0) {
                (**(code **)(*plVar28 + 8))(plVar28);
              }
            }
          }
        }
        else {
          *(undefined1 (*) [16])(plStack_1c0 + 0x10) = local_198;
          *(undefined8 *)plStack_1c0 = local_1a8._0_8_;
          *(undefined8 *)(plStack_1c0 + 8) = local_1a8._8_8_;
          *(undefined8 *)(plStack_1c0 + 0x20) = 0;
          *(undefined8 *)(plStack_1c0 + 0x28) = 0;
          *(longlong **)(plStack_1c0 + 0x20) = local_188;
          *(longlong **)(plStack_1c0 + 0x28) = plStack_180;
          plStack_1c0 = plStack_1c0 + 0x30;
        }
      }
      plVar28 = (longlong *)CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
      if (plVar28 != (longlong *)0x0) {
        LOCK();
        plVar10 = plVar28 + 1;
        *(int *)plVar10 = (int)*plVar10 + -1;
        UNLOCK();
        if ((int)*plVar10 == 0) {
          (**(code **)*plVar28)(plVar28);
          LOCK();
          piVar29 = (int *)((longlong)plVar28 + 0xc);
          *piVar29 = *piVar29 + -1;
          UNLOCK();
          if (*piVar29 == 0) {
            (**(code **)(*plVar28 + 8))(plVar28);
          }
        }
      }
      plVar19 = plVar19 + 0x20;
      if (plVar19 == plVar18) goto LAB_1406d7d31;
    }
    FUN_1406bb2c0(&local_e8,local_c8);
    if (CONCAT44(local_e8._4_4_,(undefined4)local_e8) == 0) {
      if ((*(int *)(*(longlong *)((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8) +
                   0x9c) < DAT_140809d78) && (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
        rex::RegisterLogCategory((char *)&DAT_140809d74);
        _Init_thread_footer(&DAT_140809d78);
      }
      plVar25 = rex::GetLoggerRaw(DAT_140809d74);
      auVar49 = local_198;
      if ((plVar25 != (logger *)0x0) && (*(int *)(plVar25 + 0x40) < 5)) {
        uVar41 = *(uint *)plVar19;
        local_1a8._0_4_ =
             uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
        local_198._2_2_ = 0;
        local_198._0_2_ = *(ushort *)(plVar19 + 4) << 8 | *(ushort *)(plVar19 + 4) >> 8;
        local_198._4_12_ = auVar49._4_12_;
        local_188 = (longlong *)
                    CONCAT44(local_188._4_4_,
                             (uint)(ushort)(*(ushort *)(plVar19 + 6) << 8 |
                                           *(ushort *)(plVar19 + 6) >> 8));
        local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)plVar19[8]);
        local_168 = (uint)(byte)plVar19[9];
        local_158 = (uint)(byte)plVar19[10];
        local_148 = (uint)(byte)plVar19[0xb];
        local_138 = (uint)(byte)plVar19[0xc];
        local_128 = (uint)(byte)plVar19[0xd];
        local_118 = (uint)(byte)plVar19[0xe];
        local_108 = (uint)(byte)plVar19[0xf];
        lStack_220 = (longlong)local_1a8;
        local_228 = (undefined1  [8])0x22222222222;
        local_a8._8_8_ = 0x46;
        local_a8._0_8_ = &DAT_140776223;
        FUN_140729480(&local_288,local_a8,local_228);
        lStack_220 = 0x28;
        local_228 = (undefined1  [8])"Failed to load component blend shape {}!";
        local_1a8._8_4_ = 0x3c2;
        local_1a8._0_8_ =
             "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
        ;
        local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
        in_stack_fffffffffffffb38 = (logger **)&local_288;
        FUN_140612b30(plVar25,local_1a8,4,local_228,in_stack_fffffffffffffb38);
        if (0xf < (ulonglong)local_278._8_8_) {
          plVar25 = local_288;
          if ((0xfff < local_278._8_8_ + 1) &&
             (plVar25 = *(logger **)(local_288 + -8),
             (logger *)0x1f < local_288 + (-8 - (longlong)plVar25))) {
                    /* WARNING: Subroutine does not return */
            _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
          }
          free(plVar25);
        }
      }
    }
    else {
      local_1a8 = *(undefined1 (*) [16])plVar19;
      if (CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) == 0) {
        local_198._8_8_ = 0;
        local_198._0_8_ = CONCAT44(local_e8._4_4_,(undefined4)local_e8);
      }
      else {
        LOCK();
        piVar29 = (int *)(CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) + 8);
        *piVar29 = *piVar29 + 1;
        UNLOCK();
        local_198._4_4_ = local_e8._4_4_;
        local_198._0_4_ = (undefined4)local_e8;
        local_198._12_4_ = uStack_e0._4_4_;
        local_198._8_4_ = (undefined4)uStack_e0;
      }
      if (puStack_1f0 == local_1e8) {
        FUN_1406e1250(&local_1f8);
        uVar20 = local_198._8_8_;
        if ((longlong *)local_198._8_8_ != (longlong *)0x0) {
          LOCK();
          plVar28 = (longlong *)(local_198._8_8_ + 8);
          *(int *)plVar28 = (int)*plVar28 + -1;
          UNLOCK();
          if ((int)*plVar28 == 0) {
            (*(code *)**(undefined8 **)local_198._8_8_)(local_198._8_8_);
            LOCK();
            piVar29 = (int *)(uVar20 + 0xc);
            *piVar29 = *piVar29 + -1;
            UNLOCK();
            if (*piVar29 == 0) {
              (**(code **)(*(longlong *)uVar20 + 8))(uVar20);
            }
          }
        }
      }
      else {
        *(undefined8 *)puStack_1f0 = local_1a8._0_8_;
        *(undefined8 *)(puStack_1f0 + 2) = local_1a8._8_8_;
        puStack_1f0[4] = 0;
        puStack_1f0[5] = 0;
        puStack_1f0[6] = 0;
        puStack_1f0[7] = 0;
        *(undefined8 *)(puStack_1f0 + 4) = local_198._0_8_;
        *(undefined8 *)(puStack_1f0 + 6) = local_198._8_8_;
        puStack_1f0 = puStack_1f0 + 8;
      }
    }
    plVar28 = (longlong *)CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
    if (plVar28 != (longlong *)0x0) {
      LOCK();
      plVar10 = plVar28 + 1;
      *(int *)plVar10 = (int)*plVar10 + -1;
      UNLOCK();
      if ((int)*plVar10 == 0) {
        (**(code **)*plVar28)(plVar28);
        LOCK();
        piVar29 = (int *)((longlong)plVar28 + 0xc);
        *piVar29 = *piVar29 + -1;
        UNLOCK();
        if (*piVar29 == 0) {
          (**(code **)(*plVar28 + 8))(plVar28);
        }
      }
    }
    if (local_318 != (logger *)0x0) {
      plVar25 = local_318;
      if ((0xfff < (ulonglong)(local_308 - (longlong)local_318)) &&
         (plVar25 = *(logger **)(local_318 + -8),
         (logger *)0x1f < local_318 + (-8 - (longlong)plVar25))) {
                    /* WARNING: Subroutine does not return */
        _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
      }
      free(plVar25);
    }
  }
LAB_1406d7d31:
  lVar17 = local_b8;
  local_238 = 0;
  plStack_230 = (longlong *)0x0;
  local_248 = 0;
  plStack_240 = (longlong *)0x0;
  local_258 = 0;
  plStack_250 = (longlong *)0x0;
  local_268 = 0;
  plStack_260 = (longlong *)0x0;
  local_278 = ZEXT816(0);
  local_288 = (logger *)0x0;
  uStack_280 = (longlong *)0x0;
  local_2c8 = 0;
  plStack_2c0 = (longlong *)0x0;
  local_2d8 = 0;
  plStack_2d0 = (longlong *)0x0;
  local_2e8 = 0;
  plStack_2e0 = (longlong *)0x0;
  local_2f8 = 0;
  plStack_2f0 = (longlong *)0x0;
  local_308 = 0;
  plStack_300 = (longlong *)0x0;
  local_318 = (logger *)0x0;
  plStack_310 = (logger *)0x0;
  lVar35 = local_b8 + 0x3c;
  local_208._8_4_ = 0xffffffff;
  local_208._0_8_ = 0xffffffffffffffff;
  local_208._12_4_ = 0xffffffff;
  local_218 = local_208;
  _local_228 = local_208;
  uVar43 = 0;
  do {
    while( true ) {
      lVar44 = uVar43 * 0x20;
      puVar2 = (uint *)(lVar35 + lVar44);
      local_1a8 = ZEXT816(0);
      if ((((*(int *)(lVar35 + lVar44) != 0) || (*(short *)(lVar17 + 0x40 + lVar44) != 0)) ||
          (*(short *)(lVar17 + 0x42 + lVar44) != 0)) || (*(longlong *)(puVar2 + 2) != 0)) break;
LAB_1406d7de0:
      uVar43 = uVar43 + 1;
      if (5 < uVar43) goto LAB_1406d7dc6;
    }
    FUN_1406df340(local_1a8,local_f0);
    auVar49 = local_1a8;
    local_1a8 = ZEXT816(0);
    plVar18 = (&plStack_310)[uVar43 * 2];
    *(undefined1 (*) [16])(&plStack_310 + uVar43 * 2 + -1) = auVar49;
    if (plVar18 != (logger *)0x0) {
      LOCK();
      plVar19 = plVar18 + 8;
      *(int *)plVar19 = *(int *)plVar19 + -1;
      UNLOCK();
      if (*(int *)plVar19 == 0) {
        (*(code *)**(undefined8 **)plVar18)(plVar18);
        LOCK();
        plVar19 = plVar18 + 0xc;
        *(int *)plVar19 = *(int *)plVar19 + -1;
        UNLOCK();
        if (*(int *)plVar19 == 0) {
          (**(code **)(*(longlong *)plVar18 + 8))(plVar18);
        }
      }
    }
    uVar20 = local_1a8._8_8_;
    if ((longlong *)local_1a8._8_8_ != (longlong *)0x0) {
      LOCK();
      plVar28 = (longlong *)(local_1a8._8_8_ + 8);
      *(int *)plVar28 = (int)*plVar28 + -1;
      UNLOCK();
      if ((int)*plVar28 == 0) {
        (*(code *)**(undefined8 **)local_1a8._8_8_)(local_1a8._8_8_);
        LOCK();
        piVar29 = (int *)(uVar20 + 0xc);
        *piVar29 = *piVar29 + -1;
        UNLOCK();
        if (*piVar29 == 0) {
          (**(code **)(*(longlong *)uVar20 + 8))(uVar20);
        }
      }
    }
    pauVar24 = (undefined1 (*) [16])(&plStack_310 + uVar43 * 2 + -1);
    if (*(ulonglong *)*pauVar24 != 0) {
      uVar41 = *puVar2;
      uVar41 = uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
      if (((&DAT_140780510)[uVar43 * 2] == uVar41) || ((&DAT_140780514)[uVar43 * 2] == uVar41)) {
        if ((&plStack_310)[uVar43 * 2] == (logger *)0x0) {
          auVar49._8_8_ = 0;
          auVar49._0_8_ = *(ulonglong *)*pauVar24;
        }
        else {
          LOCK();
          plVar18 = (&plStack_310)[uVar43 * 2] + 8;
          *(int *)plVar18 = *(int *)plVar18 + 1;
          UNLOCK();
          auVar49 = *pauVar24;
        }
        plVar28 = *(longlong **)(local_278 + uVar43 * 0x10 + -8);
        *(undefined1 (*) [16])(local_278 + uVar43 * 0x10 + -0x10) = auVar49;
        if (plVar28 != (longlong *)0x0) {
          LOCK();
          plVar10 = plVar28 + 1;
          *(int *)plVar10 = (int)*plVar10 + -1;
          UNLOCK();
          if ((int)*plVar10 == 0) {
            (**(code **)*plVar28)(plVar28);
            LOCK();
            piVar29 = (int *)((longlong)plVar28 + 0xc);
            *piVar29 = *piVar29 + -1;
            UNLOCK();
            if (*piVar29 == 0) {
              (**(code **)(*plVar28 + 8))(plVar28);
            }
          }
        }
        *(ulonglong *)(local_228 + uVar43 * 8) = uVar43;
        plVar18 = (&plStack_310)[uVar43 * 2];
        *(undefined8 *)*pauVar24 = 0;
        (&plStack_310)[uVar43 * 2] = (logger *)0x0;
        if (plVar18 != (logger *)0x0) {
          LOCK();
          plVar19 = plVar18 + 8;
          *(int *)plVar19 = *(int *)plVar19 + -1;
          UNLOCK();
          if (*(int *)plVar19 == 0) {
            (*(code *)**(undefined8 **)plVar18)(plVar18);
            LOCK();
            plVar19 = plVar18 + 0xc;
            *(int *)plVar19 = *(int *)plVar19 + -1;
            UNLOCK();
            if (*(int *)plVar19 == 0) {
              (**(code **)(*(longlong *)plVar18 + 8))(plVar18);
            }
          }
        }
      }
      goto LAB_1406d7de0;
    }
    if ((*(int *)(*(longlong *)((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8) +
                 0x9c) < DAT_140809d78) && (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
      rex::RegisterLogCategory((char *)&DAT_140809d74);
      _Init_thread_footer(&DAT_140809d78);
    }
    plVar18 = rex::GetLoggerRaw(DAT_140809d74);
    auVar49 = local_198;
    if ((plVar18 == (logger *)0x0) || (4 < *(int *)(plVar18 + 0x40))) goto LAB_1406d7de0;
    uVar41 = *puVar2;
    local_1a8._0_4_ =
         uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
    local_198._2_2_ = 0;
    local_198._0_2_ = (ushort)puVar2[1] << 8 | (ushort)puVar2[1] >> 8;
    local_198._4_12_ = auVar49._4_12_;
    local_188 = (longlong *)
                CONCAT44(local_188._4_4_,
                         (uint)(ushort)(*(ushort *)((longlong)puVar2 + 6) << 8 |
                                       *(ushort *)((longlong)puVar2 + 6) >> 8));
    local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)puVar2[2]);
    local_168 = (uint)*(byte *)((longlong)puVar2 + 9);
    local_158 = (uint)*(byte *)((longlong)puVar2 + 10);
    local_148 = (uint)*(byte *)((longlong)puVar2 + 0xb);
    local_138 = (uint)(byte)puVar2[3];
    local_128 = (uint)*(byte *)((longlong)puVar2 + 0xd);
    local_118 = (uint)*(byte *)((longlong)puVar2 + 0xe);
    local_108 = (uint)*(byte *)((longlong)puVar2 + 0xf);
    local_e8._0_4_ = 0x22222222;
    local_e8._4_4_ = 0x222;
    uStack_e0 = (longlong *)local_1a8;
    local_c8 = (logger *)&DAT_140776223;
    plStack_c0 = (longlong *)0x46;
    FUN_140729480(local_a8,&local_c8,&local_e8);
    local_e8._0_4_ = 0x40780b9b;
    local_e8._4_4_ = 1;
    uStack_e0._0_4_ = 0x2d;
    uStack_e0._4_4_ = 0;
    local_1a8._8_4_ = 0x40b;
    local_1a8._0_8_ =
         "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
    ;
    local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
    in_stack_fffffffffffffb38 = (logger **)local_a8;
    FUN_140612b30(plVar18,local_1a8,4,&local_e8,in_stack_fffffffffffffb38);
    if (local_90 < 0x10) goto LAB_1406d7de0;
    plVar18 = (logger *)local_a8._0_8_;
    if ((0xfff < local_90 + 1) &&
       (plVar18 = *(logger **)(local_a8._0_8_ + -8),
       (logger *)0x1f < (logger *)(local_a8._0_8_ + (-8 - (longlong)plVar18)))) {
                    /* WARNING: Subroutine does not return */
      _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
    }
    free(plVar18);
    uVar43 = uVar43 + 1;
  } while (uVar43 < 6);
LAB_1406d7dc6:
  lVar44 = 0;
  lVar17 = 0;
  do {
    if (*(ulonglong *)(local_2a8 + lVar44 + -0x70) != 0) {
      uVar41 = *(uint *)(local_b8 + 0x3c + lVar44 * 2);
      if (local_288 == (logger *)0x0) {
        plVar28 = (longlong *)local_228;
        pauVar24 = (undefined1 (*) [16])&local_288;
        if ((uVar41 & 0xff7fffff) != 0) goto LAB_1406d8e87;
LAB_1406d8f90:
        if (*(longlong *)((longlong)&plStack_310 + lVar44) == 0) {
          auVar50._8_8_ = 0;
          auVar50._0_8_ = *(ulonglong *)(local_2a8 + lVar44 + -0x70);
          plVar10 = *(longlong **)(*pauVar24 + 8);
          *pauVar24 = auVar50;
        }
        else {
          LOCK();
          piVar29 = (int *)(*(longlong *)((longlong)&plStack_310 + lVar44) + 8);
          *piVar29 = *piVar29 + 1;
          UNLOCK();
          plVar10 = *(longlong **)(*pauVar24 + 8);
          *pauVar24 = *(undefined1 (*) [16])(local_2a8 + lVar44 + -0x70);
        }
        if (plVar10 != (longlong *)0x0) {
          LOCK();
          plVar1 = plVar10 + 1;
          *(int *)plVar1 = (int)*plVar1 + -1;
          UNLOCK();
          if ((int)*plVar1 == 0) {
            (**(code **)*plVar10)(plVar10);
            LOCK();
            piVar29 = (int *)((longlong)plVar10 + 0xc);
            *piVar29 = *piVar29 + -1;
            UNLOCK();
            if (*piVar29 == 0) {
              (**(code **)(*plVar10 + 8))(plVar10);
            }
          }
        }
        *plVar28 = lVar17;
      }
      else {
LAB_1406d8e87:
        if (local_278._0_8_ == 0) {
          plVar28 = &lStack_220;
          pauVar24 = &local_278;
          if ((uVar41 & 0xffdfffff) == 0) goto LAB_1406d8f90;
        }
        if (local_268 == 0) {
          plVar28 = (longlong *)local_218;
          pauVar24 = (undefined1 (*) [16])&local_268;
          if ((uVar41 & 0xffbfffff) == 0) goto LAB_1406d8f90;
        }
        if (local_258 == 0) {
          plVar28 = (longlong *)(local_218 + 8);
          pauVar24 = (undefined1 (*) [16])&local_258;
          if ((uVar41 == 0x100) || (uVar41 == 0x400)) goto LAB_1406d8f90;
        }
        if (local_248 == 0) {
          plVar28 = (longlong *)local_208;
          pauVar24 = (undefined1 (*) [16])&local_248;
          if ((uVar41 == 0x100) || (uVar41 == 0x400)) goto LAB_1406d8f90;
        }
        if (local_238 == 0) {
          plVar28 = (longlong *)(local_208 + 8);
          pauVar24 = (undefined1 (*) [16])&local_238;
          if ((uVar41 == 0x100) || (uVar41 == 0x200)) goto LAB_1406d8f90;
        }
      }
    }
    lVar17 = lVar17 + 1;
    lVar44 = lVar44 + 0x10;
  } while (lVar17 != 6);
  if (((DAT_14080b128 != '\0') && ((uint *)local_278._0_8_ != (uint *)0x0)) &&
     ((*(uint *)local_278._0_8_ & 0x3f) == 0x14)) {
    lVar17 = *(longlong *)(local_278._0_8_ + 0x28);
    if (0xf < (ulonglong)(*(longlong *)(local_278._0_8_ + 0x30) - lVar17)) {
      uVar41 = 0;
      uVar43 = 0x10;
      do {
        uVar41 = (uint)((*(byte *)(lVar17 + -5 + uVar43) & 0x18) == 0 &&
                       0x2e0 < (*(byte *)(lVar17 + -6 + uVar43) & 7) << 8) +
                 ((*(byte *)(lVar17 + -7 + uVar43) & 0x18) == 0 &&
                 0x2e0 < (*(byte *)(lVar17 + -8 + uVar43) & 7) << 8) + uVar41;
        uVar43 = uVar43 + 0x10;
      } while (uVar43 <= (ulonglong)(*(longlong *)(local_278._0_8_ + 0x30) - lVar17));
      if (uVar41 < 0x18) {
        uVar43 = 0x10;
        do {
          bVar6 = *(byte *)(lVar17 + -7 + uVar43);
          uVar41 = bVar6 & 0x1f;
          if (7 < uVar41) {
            bVar7 = *(byte *)(lVar17 + -8 + uVar43);
            uVar37 = (ushort)(CONCAT11(bVar7,bVar6) >> 5) & 0x3f;
            uVar41 = (uVar41 >> 4) + uVar41 * 2;
            if (uVar37 <= uVar41) {
              uVar37 = uVar41;
            }
            *(byte *)(lVar17 + -8 + uVar43) = bVar7 & 0xf8 | (byte)((uVar37 << 5) >> 8);
            *(char *)(*(longlong *)(local_278._0_8_ + 0x28) + -7 + uVar43) = (char)(uVar37 << 5);
            lVar17 = *(longlong *)(local_278._0_8_ + 0x28);
          }
          bVar6 = *(byte *)(lVar17 + -5 + uVar43);
          uVar41 = bVar6 & 0x1f;
          if (7 < uVar41) {
            bVar7 = *(byte *)(lVar17 + -6 + uVar43);
            uVar37 = (ushort)(CONCAT11(bVar7,bVar6) >> 5) & 0x3f;
            uVar41 = (uVar41 >> 4) + uVar41 * 2;
            if (uVar37 <= uVar41) {
              uVar37 = uVar41;
            }
            *(byte *)(lVar17 + -6 + uVar43) = bVar7 & 0xf8 | (byte)((uVar37 << 5) >> 8);
            *(char *)(*(longlong *)(local_278._0_8_ + 0x28) + -5 + uVar43) = (char)(uVar37 << 5);
            lVar17 = *(longlong *)(local_278._0_8_ + 0x28);
          }
          uVar43 = uVar43 + 0x10;
        } while (uVar43 <= (ulonglong)(*(longlong *)(local_278._0_8_ + 0x30) - lVar17));
      }
    }
  }
  if (((0xff < *(uint *)(local_b8 + 0x110)) && (local_248 == 0)) &&
     (((byte)local_2b0 & (lStack_220 != -1 && (uint *)local_278._0_8_ != (uint *)0x0)) == 1)) {
    lVar35 = lVar35 + lStack_220 * 0x20;
    cVar47 = FUN_1406be9b0(lVar35);
    if (cVar47 != '\0') {
      uVar46 = *(ushort *)(lVar35 + 4);
      uVar43 = (ulonglong)(ushort)(uVar46 << 8 | uVar46 >> 8);
      lVar35 = *(longlong *)(local_f0 + 0x20);
      if (uVar43 < (ulonglong)((*(longlong *)(local_f0 + 0x28) - lVar35 >> 3) * -0x7b425ed097b425ed)
         ) {
        lVar17 = uVar43 * 0xd8;
        piVar29 = (int *)(lVar35 + lVar17 + 0x9c);
        cVar47 = FUN_1406e0f70(piVar29);
        if (((cVar47 == '\0') && (*piVar29 == 0x400)) &&
           (uVar46 = *(ushort *)(lVar35 + lVar17 + 0xa0),
           (ulonglong)(ushort)(uVar46 << 8 | uVar46 >> 8) <
           (ulonglong)
           ((*(longlong *)(local_f0 + 0x28) - *(longlong *)(local_f0 + 0x20) >> 3) *
           -0x7b425ed097b425ed))) {
          FUN_1406df340(local_1a8,local_f0);
          if (local_1a8._0_8_ != 0) {
            FUN_1406e1070(&local_248,local_1a8);
          }
          FUN_1406e1030(local_1a8);
        }
      }
    }
  }
  puVar2 = puStack_1f0;
  puVar30 = local_1f8;
LAB_1406d9c0b:
  plVar18 = plStack_1c0;
  if (puVar30 != puVar2) {
    plVar19 = local_1c8;
    if (*(int *)(*(longlong *)(puVar30 + 4) + 0x34) == 0x2000000) {
      for (; plVar19 != plVar18; plVar19 = plVar19 + 0x30) {
        cVar47 = FUN_1406baf90(*(undefined8 *)(puVar30 + 4),plVar19);
        if (cVar47 != '\0') {
          local_a8 = ZEXT816(0);
          if (local_1c8 == plStack_1c0) goto LAB_1406d9d20;
          plVar18 = local_1c8;
          goto LAB_1406d9c9d;
        }
      }
    }
    goto LAB_1406d9c07;
  }
  local_f8 = plStack_1c0;
  plVar18 = local_1c8;
  while( true ) {
    puVar2 = puStack_1f0;
    fVar16 = DAT_1407807c0;
    fVar15 = DAT_1407807bc;
    if (plVar18 == local_f8) break;
    for (puVar30 = local_1f8; puVar30 != puVar2; puVar30 = puVar30 + 8) {
      cVar47 = FUN_1406baf90(*(undefined8 *)(puVar30 + 4),plVar18);
      if (cVar47 != '\0') {
        if (*(longlong *)(plVar18 + 0x28) == 0) {
          uStack_3e0 = 0;
        }
        else {
          LOCK();
          piVar29 = (int *)(*(longlong *)(plVar18 + 0x28) + 8);
          *piVar29 = *piVar29 + 1;
          UNLOCK();
          uStack_3e0 = *(undefined8 *)(plVar18 + 0x28);
        }
        local_3e8 = *(undefined8 *)(plVar18 + 0x20);
        if (*(longlong *)(puVar30 + 6) == 0) {
          uStack_350 = 0;
        }
        else {
          LOCK();
          piVar29 = (int *)(*(longlong *)(puVar30 + 6) + 8);
          *piVar29 = *piVar29 + 1;
          UNLOCK();
          uStack_350 = *(undefined8 *)(puVar30 + 6);
        }
        local_358 = *(undefined8 *)(puVar30 + 4);
        cVar47 = FUN_1406bd830(&local_358,plVar18);
        if (cVar47 == '\0') {
          if (*(int *)(*(longlong *)
                        ((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8) + 0x9c) <
              DAT_140809d78) {
            FUN_14074767c(&DAT_140809d78);
            if (DAT_140809d78 == -1) {
              rex::RegisterLogCategory((char *)&DAT_140809d74);
              _Init_thread_footer(&DAT_140809d78);
            }
          }
          plVar19 = rex::GetLoggerRaw(DAT_140809d74);
          if ((plVar19 != (logger *)0x0) && (*(int *)(plVar19 + 0x40) < 5)) {
            uVar41 = *(uint *)plVar18;
            local_168 = (uint)(byte)plVar18[9];
            local_158 = (uint)(byte)plVar18[10];
            local_148 = (uint)(byte)plVar18[0xb];
            local_138 = (uint)(byte)plVar18[0xc];
            local_128 = (uint)(byte)plVar18[0xd];
            local_118 = (uint)(byte)plVar18[0xe];
            local_108 = (uint)(byte)plVar18[0xf];
            local_e8._0_4_ = 0x22222222;
            local_e8._4_4_ = 0x222;
            local_c8 = (logger *)&DAT_140776223;
            plStack_c0 = (longlong *)0x46;
            local_1a8._0_4_ =
                 uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18
            ;
            local_198._0_4_ =
                 (uint)(ushort)(*(ushort *)(plVar18 + 4) << 8 | *(ushort *)(plVar18 + 4) >> 8);
            local_188._0_4_ =
                 (uint)(ushort)(*(ushort *)(plVar18 + 6) << 8 | *(ushort *)(plVar18 + 6) >> 8);
            local_178._0_4_ = (uint)(byte)plVar18[8];
            uStack_e0 = (longlong *)local_1a8;
            FUN_140729480(local_a8,&local_c8,&local_e8);
            uVar41 = *puVar30;
            local_1a8._0_4_ =
                 uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18
            ;
            local_198._2_2_ = 0;
            local_198._0_2_ = (ushort)puVar30[1] << 8 | (ushort)puVar30[1] >> 8;
            local_188 = (longlong *)
                        CONCAT44(local_188._4_4_,
                                 (uint)(ushort)(*(ushort *)((longlong)puVar30 + 6) << 8 |
                                               *(ushort *)((longlong)puVar30 + 6) >> 8));
            local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)puVar30[2]);
            local_168 = (uint)*(byte *)((longlong)puVar30 + 9);
            local_158 = (uint)*(byte *)((longlong)puVar30 + 10);
            local_148 = (uint)*(byte *)((longlong)puVar30 + 0xb);
            local_138 = (uint)(byte)puVar30[3];
            local_128 = (uint)*(byte *)((longlong)puVar30 + 0xd);
            local_118 = (uint)*(byte *)((longlong)puVar30 + 0xe);
            local_108 = (uint)*(byte *)((longlong)puVar30 + 0xf);
            local_c8 = (logger *)0x22222222222;
            local_1d8 = &DAT_140776223;
            local_1d0 = 0x46;
            in_stack_fffffffffffffb38 = (logger **)&local_e8;
            plStack_c0 = (longlong *)local_1a8;
            FUN_140729480(in_stack_fffffffffffffb38,&local_1d8,&local_c8);
            local_c8 = (logger *)0x140780bc9;
            plStack_c0 = (longlong *)0x2b;
            local_1a8._8_4_ = 0x46a;
            local_1a8._0_8_ =
                 "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
            ;
            local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
            FUN_1406e4790(plVar19,local_1a8,4,&local_c8,in_stack_fffffffffffffb38,local_a8);
            if (0xf < local_d0) {
              pvVar14 = (void *)CONCAT44(local_e8._4_4_,(undefined4)local_e8);
              pvVar26 = pvVar14;
              if ((0xfff < local_d0 + 1) &&
                 (pvVar26 = *(void **)((longlong)pvVar14 + -8),
                 0x1f < (ulonglong)((longlong)pvVar14 + (-8 - (longlong)pvVar26)))) {
                    /* WARNING: Subroutine does not return */
                _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
              }
              free(pvVar26);
            }
            if (0xf < local_90) {
              plVar19 = (logger *)local_a8._0_8_;
              if ((0xfff < local_90 + 1) &&
                 (plVar19 = *(logger **)(local_a8._0_8_ + -8),
                 (logger *)0x1f < (logger *)(local_a8._0_8_ + (-8 - (longlong)plVar19)))) {
                    /* WARNING: Subroutine does not return */
                _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
              }
              free(plVar19);
            }
          }
        }
        if (*(int *)(*(longlong *)((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8)
                    + 0x9c) < DAT_140809d78) {
          FUN_14074767c(&DAT_140809d78);
          if (DAT_140809d78 == -1) {
            rex::RegisterLogCategory((char *)&DAT_140809d74);
            _Init_thread_footer(&DAT_140809d78);
          }
        }
        plVar19 = rex::GetLoggerRaw(DAT_140809d74);
        if ((plVar19 != (logger *)0x0) && (*(int *)(plVar19 + 0x40) < 2)) {
          uVar41 = *(uint *)plVar18;
          local_168 = (uint)(byte)plVar18[9];
          local_158 = (uint)(byte)plVar18[10];
          local_148 = (uint)(byte)plVar18[0xb];
          local_138 = (uint)(byte)plVar18[0xc];
          local_128 = (uint)(byte)plVar18[0xd];
          local_118 = (uint)(byte)plVar18[0xe];
          local_108 = (uint)(byte)plVar18[0xf];
          local_e8._0_4_ = 0x22222222;
          local_e8._4_4_ = 0x222;
          local_c8 = (logger *)&DAT_140776223;
          plStack_c0 = (longlong *)0x46;
          local_1a8._0_4_ =
               uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
          local_198._0_4_ =
               (uint)(ushort)(*(ushort *)(plVar18 + 4) << 8 | *(ushort *)(plVar18 + 4) >> 8);
          local_188._0_4_ =
               (uint)(ushort)(*(ushort *)(plVar18 + 6) << 8 | *(ushort *)(plVar18 + 6) >> 8);
          local_178._0_4_ = (uint)(byte)plVar18[8];
          uStack_e0 = (longlong *)local_1a8;
          FUN_140729480(local_a8,&local_c8,&local_e8);
          uVar41 = *puVar30;
          local_1a8._0_4_ =
               uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
          local_198._2_2_ = 0;
          local_198._0_2_ = (ushort)puVar30[1] << 8 | (ushort)puVar30[1] >> 8;
          local_188 = (longlong *)
                      CONCAT44(local_188._4_4_,
                               (uint)(ushort)(*(ushort *)((longlong)puVar30 + 6) << 8 |
                                             *(ushort *)((longlong)puVar30 + 6) >> 8));
          local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)puVar30[2]);
          local_168 = (uint)*(byte *)((longlong)puVar30 + 9);
          local_158 = (uint)*(byte *)((longlong)puVar30 + 10);
          local_148 = (uint)*(byte *)((longlong)puVar30 + 0xb);
          local_138 = (uint)(byte)puVar30[3];
          local_128 = (uint)*(byte *)((longlong)puVar30 + 0xd);
          local_118 = (uint)*(byte *)((longlong)puVar30 + 0xe);
          local_108 = (uint)*(byte *)((longlong)puVar30 + 0xf);
          local_c8 = (logger *)0x22222222222;
          local_1d8 = &DAT_140776223;
          local_1d0 = 0x46;
          in_stack_fffffffffffffb38 = (logger **)&local_e8;
          plStack_c0 = (longlong *)local_1a8;
          FUN_140729480(in_stack_fffffffffffffb38,&local_1d8,&local_c8);
          local_c8 = (logger *)0x140780bf5;
          plStack_c0 = (longlong *)0x23;
          local_1a8._8_4_ = 0x46e;
          local_1a8._0_8_ =
               "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
          ;
          local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
          FUN_1406e4790(plVar19,local_1a8,1,&local_c8,in_stack_fffffffffffffb38,local_a8);
          if (0xf < local_d0) {
            pvVar14 = (void *)CONCAT44(local_e8._4_4_,(undefined4)local_e8);
            pvVar26 = pvVar14;
            if ((0xfff < local_d0 + 1) &&
               (pvVar26 = *(void **)((longlong)pvVar14 + -8),
               0x1f < (ulonglong)((longlong)pvVar14 + (-8 - (longlong)pvVar26)))) {
                    /* WARNING: Subroutine does not return */
              _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
            }
            free(pvVar26);
          }
          if (0xf < local_90) {
            plVar19 = (logger *)local_a8._0_8_;
            if ((0xfff < local_90 + 1) &&
               (plVar19 = *(logger **)(local_a8._0_8_ + -8),
               (logger *)0x1f < (logger *)(local_a8._0_8_ + (-8 - (longlong)plVar19)))) {
                    /* WARNING: Subroutine does not return */
              _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
            }
            free(plVar19);
          }
        }
      }
    }
    plVar18 = plVar18 + 0x30;
  }
  local_420 = plStack_1c0;
  plVar18 = local_1c8;
  while (plVar18 != local_420) {
    lVar35 = *(longlong *)(plVar18 + 0x20);
    auVar52._8_8_ = 0;
    auVar52._0_8_ = local_198._8_8_;
    local_198 = auVar52 << 0x40;
    local_428 = plVar18;
    lVar17 = FUN_1407475f0(0x28);
    *(longlong *)lVar17 = lVar17;
    *(longlong *)(lVar17 + 8) = lVar17;
    local_1a8._8_8_ = lVar17;
    local_198._8_8_ = 0;
    local_188 = (longlong *)0x0;
    plStack_180 = (void *)0x0;
    local_178 = (logger *)0x7;
    local_170 = 8;
    local_1a8._0_4_ = 0x3f800000;
    plVar28 = (longlong *)FUN_1407475f0(0x80);
    if (plStack_180 != (longlong *)local_198._8_8_) {
      pvVar26 = (void *)local_198._8_8_;
      if ((0xfff < (ulonglong)((longlong)plStack_180 - local_198._8_8_)) &&
         (pvVar26 = *(void **)(local_198._8_8_ + -8),
         0x1f < (ulonglong)(local_198._8_8_ + (-8 - (longlong)pvVar26)))) {
                    /* WARNING: Subroutine does not return */
        _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
      }
      free(pvVar26);
    }
    local_198._8_8_ = plVar28;
    local_188 = plVar28 + 0x10;
    *plVar28 = lVar17;
    plVar28[1] = lVar17;
    plVar28[2] = lVar17;
    plVar28[3] = lVar17;
    plVar28[4] = lVar17;
    plVar28[5] = lVar17;
    plVar28[6] = lVar17;
    plVar28[7] = lVar17;
    plVar28[8] = lVar17;
    plVar28[9] = lVar17;
    plVar28[10] = lVar17;
    plVar28[0xb] = lVar17;
    plVar28[0xc] = lVar17;
    plVar28[0xd] = lVar17;
    plVar28[0xe] = lVar17;
    plVar28[0xf] = lVar17;
    lVar17 = *(longlong *)(lVar35 + 0x28);
    local_430 = *(longlong *)(lVar35 + 0x30);
    plStack_180 = local_188;
    if (lVar17 == local_430) {
      uVar43 = (longlong)local_188 - (longlong)plVar28;
joined_r0x0001406daef4:
      if (0xfff < uVar43) {
        if (0x1f < (ulonglong)((longlong)plVar28 + (-8 - plVar28[-1]))) {
                    /* WARNING: Subroutine does not return */
          _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
        }
        plVar28 = (longlong *)plVar28[-1];
      }
      free(plVar28);
      local_198._8_8_ = 0;
      local_188 = (longlong *)0x0;
      plStack_180 = (longlong *)0x0;
    }
    else {
      do {
        pfVar31 = *(float **)(lVar17 + 0x38);
        local_440 = *(float **)(lVar17 + 0x40);
        local_438 = lVar17;
        if (pfVar31 != local_440) {
          do {
            fVar3 = *pfVar31;
            auVar49 = roundss(ZEXT416((uint)(fVar3 / fVar15)),ZEXT416((uint)(fVar3 / fVar15)),9);
            local_448 = (ulonglong)(uint)(int)auVar49._0_4_;
            fVar4 = pfVar31[1];
            auVar50 = roundss(ZEXT416((uint)(fVar4 / fVar15)),ZEXT416((uint)(fVar4 / fVar15)),9);
            fVar5 = pfVar31[2];
            auVar52 = roundss(ZEXT416((uint)(fVar5 / fVar15)),ZEXT416((uint)(fVar5 / fVar15)),9);
            local_478 = (ulonglong)(int)auVar52._0_4_;
            local_330 = (undefined8 *)(longlong)(int)auVar50._0_4_;
            local_f8 = local_178;
            local_468 = local_478 - 1;
            local_338 = (undefined8 *)(local_478 + 0xfffff);
            local_2b0 = (local_468 >> 8 & 0xff ^
                        (local_468 & 0xff ^ 0xcbf29ce484222325) * 0x100000001b3) * 0x100000001b3;
            local_468 = local_468 & 0xffff;
            local_378 = local_478 + 0x100000;
            local_480 = ((ulonglong)(byte)((uint)(int)auVar52._0_4_ >> 8) ^
                        (local_478 & 0xff ^ 0xcbf29ce484222325) * 0x100000001b3) * 0x100000001b3;
            local_458 = local_478 + 1;
            local_460 = local_478 & 0xffff;
            local_478 = local_478 + 0x100001;
            local_470 = (local_458 >> 8 & 0xff ^
                        (local_458 & 0xff ^ 0xcbf29ce484222325) * 0x100000001b3) * 0x100000001b3;
            local_458 = local_458 & 0xffff;
            uVar43 = 0xffffffff;
            do {
              local_450 = uVar43;
              local_290 = (undefined8 *)
                          (((ulonglong)(uint)((int)local_450 + (int)auVar49._0_4_) << 0x2a) +
                          0x4000000000000000);
              lVar35 = -1;
              do {
                uVar32 = ((longlong)local_330 + lVar35) * 0x200000 + 0x20000000000U |
                         (ulonglong)local_290;
                uVar42 = uVar32 | (ulonglong)local_338;
                uVar40 = uVar42 >> 0x18 & 0xff;
                uVar38 = uVar42 >> 0x10 & 0xff;
                uVar27 = uVar42 >> 0x20 & 0xff;
                uVar43 = uVar42 >> 0x28 & 0xff;
                uVar45 = uVar42 >> 0x30 & 0xff;
                lVar44 = (((((((local_2b0 ^ uVar38) * 0x100000001b3 ^ uVar40) * 0x100000001b3 ^
                             uVar27) * 0x100000001b3 ^ uVar43) * 0x100000001b3 ^ uVar45) *
                           0x100000001b3 ^ uVar42 >> 0x38) * 0x100000001b3 & (ulonglong)local_178) *
                         0x10;
                lVar17 = *(longlong *)(local_198._8_8_ + 8 + lVar44);
                local_370 = pfVar31;
                if (lVar17 != local_1a8._8_8_) {
                  lVar39 = ((ulonglong)(uint)((int)uVar38 << 0x10) |
                           (ulonglong)(uint)((int)uVar40 << 0x18) |
                           uVar27 << 0x20 |
                           uVar43 << 0x28 | uVar45 << 0x30 | uVar42 & 0xff00000000000000) +
                           local_468;
                  if (lVar39 != *(longlong *)(lVar17 + 0x10)) {
                    do {
                      if (lVar17 == *(longlong *)(local_198._8_8_ + lVar44)) goto LAB_1406dac0a;
                      lVar17 = *(longlong *)(lVar17 + 8);
                    } while (lVar39 != *(longlong *)(lVar17 + 0x10));
                  }
                  if ((lVar17 == local_1a8._8_8_) ||
                     (fVar51 = fVar3 - *(float *)(lVar17 + 0x18),
                     fVar53 = fVar4 - *(float *)(lVar17 + 0x1c),
                     fVar54 = fVar5 - *(float *)(lVar17 + 0x20),
                     fVar16 <= fVar54 * fVar54 + fVar51 * fVar51 + fVar53 * fVar53))
                  goto LAB_1406dac0a;
LAB_1406dae42:
                  pfVar31[2] = *(float *)(lVar17 + 0x20);
                  *(undefined8 *)pfVar31 = *(undefined8 *)(lVar17 + 0x18);
                  goto LAB_1406dae56;
                }
LAB_1406dac0a:
                uVar42 = uVar32 | local_378;
                uVar40 = uVar42 >> 0x18 & 0xff;
                uVar38 = uVar42 >> 0x10 & 0xff;
                uVar27 = uVar42 >> 0x20 & 0xff;
                uVar43 = uVar42 >> 0x28 & 0xff;
                uVar45 = uVar42 >> 0x30 & 0xff;
                lVar44 = (((((((local_480 ^ uVar38) * 0x100000001b3 ^ uVar40) * 0x100000001b3 ^
                             uVar27) * 0x100000001b3 ^ uVar43) * 0x100000001b3 ^ uVar45) *
                           0x100000001b3 ^ uVar42 >> 0x38) * 0x100000001b3 & (ulonglong)local_178) *
                         0x10;
                lVar17 = *(longlong *)(local_198._8_8_ + 8 + lVar44);
                if (lVar17 != local_1a8._8_8_) {
                  lVar39 = ((ulonglong)(uint)((int)uVar38 << 0x10) |
                           (ulonglong)(uint)((int)uVar40 << 0x18) |
                           uVar27 << 0x20 |
                           uVar43 << 0x28 | uVar45 << 0x30 | uVar42 & 0xff00000000000000) +
                           local_460;
                  if (lVar39 != *(longlong *)(lVar17 + 0x10)) {
                    do {
                      if (lVar17 == *(longlong *)(local_198._8_8_ + lVar44)) goto LAB_1406dad2a;
                      lVar17 = *(longlong *)(lVar17 + 8);
                    } while (lVar39 != *(longlong *)(lVar17 + 0x10));
                  }
                  if ((lVar17 != local_1a8._8_8_) &&
                     (fVar51 = fVar3 - *(float *)(lVar17 + 0x18),
                     fVar53 = fVar4 - *(float *)(lVar17 + 0x1c),
                     fVar54 = fVar5 - *(float *)(lVar17 + 0x20),
                     fVar54 * fVar54 + fVar51 * fVar51 + fVar53 * fVar53 < fVar16))
                  goto LAB_1406dae42;
                }
LAB_1406dad2a:
                uVar32 = uVar32 | local_478;
                uVar40 = uVar32 >> 0x18 & 0xff;
                uVar38 = uVar32 >> 0x10 & 0xff;
                uVar27 = uVar32 >> 0x20 & 0xff;
                uVar43 = uVar32 >> 0x28 & 0xff;
                uVar42 = uVar32 >> 0x30 & 0xff;
                lVar44 = (((((((local_470 ^ uVar38) * 0x100000001b3 ^ uVar40) * 0x100000001b3 ^
                             uVar27) * 0x100000001b3 ^ uVar43) * 0x100000001b3 ^ uVar42) *
                           0x100000001b3 ^ uVar32 >> 0x38) * 0x100000001b3 & (ulonglong)local_178) *
                         0x10;
                lVar17 = *(longlong *)(local_198._8_8_ + 8 + lVar44);
                if (lVar17 != local_1a8._8_8_) {
                  lVar39 = ((ulonglong)(uint)((int)uVar38 << 0x10) |
                           (ulonglong)(uint)((int)uVar40 << 0x18) |
                           uVar27 << 0x20 |
                           uVar43 << 0x28 | uVar42 << 0x30 | uVar32 & 0xff00000000000000) +
                           local_458;
                  if (lVar39 != *(longlong *)(lVar17 + 0x10)) {
                    do {
                      if (lVar17 == *(longlong *)(local_198._8_8_ + lVar44)) goto LAB_1406daac0;
                      lVar17 = *(longlong *)(lVar17 + 8);
                    } while (lVar39 != *(longlong *)(lVar17 + 0x10));
                  }
                  if ((lVar17 != local_1a8._8_8_) &&
                     (fVar51 = fVar3 - *(float *)(lVar17 + 0x18),
                     fVar53 = fVar4 - *(float *)(lVar17 + 0x1c),
                     fVar54 = fVar5 - *(float *)(lVar17 + 0x20),
                     fVar54 * fVar54 + fVar51 * fVar51 + fVar53 * fVar53 < fVar16))
                  goto LAB_1406dae42;
                }
LAB_1406daac0:
                lVar35 = lVar35 + 1;
              } while (lVar35 != 2);
              uVar41 = (int)local_450 + 1;
              uVar43 = (ulonglong)uVar41;
            } while (uVar41 != 2);
            uVar43 = (longlong)local_330 * 0x200000 + 0x20000000000U |
                     (local_448 << 0x2a) + 0x4000000000000000 | local_378;
            local_e8._0_4_ = (undefined4)uVar43;
            local_e8._4_4_ = (undefined4)(uVar43 >> 0x20);
            FUN_1406e3100(local_1a8,local_a8);
LAB_1406dae56:
            pfVar31 = pfVar31 + 0xe;
          } while (pfVar31 != local_440);
        }
        lVar17 = local_438 + 0x68;
      } while (lVar17 != local_430);
      if ((longlong *)local_198._8_8_ != (longlong *)0x0) {
        uVar43 = (longlong)plStack_180 - local_198._8_8_;
        plVar28 = (longlong *)local_198._8_8_;
        goto joined_r0x0001406daef4;
      }
    }
    **(undefined8 **)(local_1a8._8_8_ + 8) = 0;
    puVar33 = *(undefined8 **)local_1a8._8_8_;
    while (puVar33 != (undefined8 *)0x0) {
      puVar11 = (undefined8 *)*puVar33;
      free(puVar33);
      puVar33 = puVar11;
    }
    free((void *)local_1a8._8_8_);
    plVar18 = local_428 + 0x30;
  }
  local_c8 = (logger *)0x0;
  plStack_c0 = (longlong *)0x0;
  local_198 = ZEXT816(0);
  local_1a8 = ZEXT816(0);
  if ((local_33c & 0x1000) != 0) {
    if (((((*(int *)(local_b8 + 0x160) == 0) && (*(short *)(local_b8 + 0x164) == 0)) &&
         (*(short *)(local_b8 + 0x166) == 0)) && (*(longlong *)(local_b8 + 0x168) == 0)) ||
       ((*(byte *)(local_b8 + 0x170) & 0x10) == 0)) {
      if ((((*(int *)(local_b8 + 0x180) != 0) || (*(short *)(local_b8 + 0x184) != 0)) ||
          ((*(short *)(local_b8 + 0x186) != 0 || (*(longlong *)(local_b8 + 0x188) != 0)))) &&
         ((*(byte *)(local_b8 + 400) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x180);
        goto LAB_1406db444;
      }
      if ((((*(int *)(local_b8 + 0x1a0) != 0) || (*(short *)(local_b8 + 0x1a4) != 0)) ||
          ((*(short *)(local_b8 + 0x1a6) != 0 || (*(longlong *)(local_b8 + 0x1a8) != 0)))) &&
         ((*(byte *)(local_b8 + 0x1b0) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x1a0);
        goto LAB_1406db444;
      }
      if (((((*(int *)(local_b8 + 0x1c0) != 0) || (*(short *)(local_b8 + 0x1c4) != 0)) ||
           (*(short *)(local_b8 + 0x1c6) != 0)) || (*(longlong *)(local_b8 + 0x1c8) != 0)) &&
         ((*(byte *)(local_b8 + 0x1d0) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x1c0);
        goto LAB_1406db444;
      }
      if ((((*(int *)(local_b8 + 0x1e0) != 0) || (*(short *)(local_b8 + 0x1e4) != 0)) ||
          ((*(short *)(local_b8 + 0x1e6) != 0 || (*(longlong *)(local_b8 + 0x1e8) != 0)))) &&
         ((*(byte *)(local_b8 + 0x1f0) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x1e0);
        goto LAB_1406db444;
      }
      if ((((*(int *)(local_b8 + 0x200) != 0) || (*(short *)(local_b8 + 0x204) != 0)) ||
          ((*(short *)(local_b8 + 0x206) != 0 || (*(longlong *)(local_b8 + 0x208) != 0)))) &&
         ((*(byte *)(local_b8 + 0x210) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x200);
        goto LAB_1406db444;
      }
      if (((((*(int *)(local_b8 + 0x220) != 0) || (*(short *)(local_b8 + 0x224) != 0)) ||
           (*(short *)(local_b8 + 0x226) != 0)) || (*(longlong *)(local_b8 + 0x228) != 0)) &&
         ((*(byte *)(local_b8 + 0x230) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x220);
        goto LAB_1406db444;
      }
      if ((((*(int *)(local_b8 + 0x240) != 0) || (*(short *)(local_b8 + 0x244) != 0)) ||
          ((*(short *)(local_b8 + 0x246) != 0 || (*(longlong *)(local_b8 + 0x248) != 0)))) &&
         ((*(byte *)(local_b8 + 0x250) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x240);
        goto LAB_1406db444;
      }
      if ((((*(int *)(local_b8 + 0x260) != 0) || (*(short *)(local_b8 + 0x264) != 0)) ||
          ((*(short *)(local_b8 + 0x266) != 0 || (*(longlong *)(local_b8 + 0x268) != 0)))) &&
         ((*(byte *)(local_b8 + 0x270) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x260);
        goto LAB_1406db444;
      }
      if (((((*(int *)(local_b8 + 0x280) != 0) || (*(short *)(local_b8 + 0x284) != 0)) ||
           (*(short *)(local_b8 + 0x286) != 0)) || (*(longlong *)(local_b8 + 0x288) != 0)) &&
         ((*(byte *)(local_b8 + 0x290) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x280);
        goto LAB_1406db444;
      }
      if ((((*(int *)(local_b8 + 0x2a0) != 0) || (*(short *)(local_b8 + 0x2a4) != 0)) ||
          ((*(short *)(local_b8 + 0x2a6) != 0 || (*(longlong *)(local_b8 + 0x2a8) != 0)))) &&
         ((*(byte *)(local_b8 + 0x2b0) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x2a0);
        goto LAB_1406db444;
      }
      if ((((*(int *)(local_b8 + 0x2c0) != 0) || (*(short *)(local_b8 + 0x2c4) != 0)) ||
          ((*(short *)(local_b8 + 0x2c6) != 0 || (*(longlong *)(local_b8 + 0x2c8) != 0)))) &&
         ((*(byte *)(local_b8 + 0x2d0) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x2c0);
        goto LAB_1406db444;
      }
      if (((((*(int *)(local_b8 + 0x2e0) != 0) || (*(short *)(local_b8 + 0x2e4) != 0)) ||
           (*(short *)(local_b8 + 0x2e6) != 0)) || (*(longlong *)(local_b8 + 0x2e8) != 0)) &&
         ((*(byte *)(local_b8 + 0x2f0) & 0x10) != 0)) {
        pauVar24 = (undefined1 (*) [16])(local_b8 + 0x2e0);
        goto LAB_1406db444;
      }
LAB_1406db48a:
      local_a8 = (undefined1  [16])0x0;
      if (local_1a8._8_8_ == 0) goto LAB_1406db5f8;
    }
    else {
      pauVar24 = (undefined1 (*) [16])(local_b8 + 0x160);
LAB_1406db444:
      local_1a8 = *pauVar24;
      local_198 = pauVar24[1];
      if (((local_1a8._0_4_ == 0) && (local_1a8._4_2_ == 0)) && (local_1a8._6_2_ == 0))
      goto LAB_1406db48a;
    }
    local_380 = (uint)(param_8 == 0) * 4 + 2;
    local_388 = local_ac;
    local_384 = local_ac;
    local_37c = local_ac;
    local_a8 = (undefined1  [16])0x0;
    local_98 = (undefined8 *)0x0;
    in_stack_fffffffffffffb38 = (logger **)local_a8;
    cVar47 = FUN_1406dde80(local_f0,local_1a8,&local_1d8,local_488,in_stack_fffffffffffffb38);
    if (cVar47 == '\0') {
      local_e8._0_4_ = 0;
      local_e8._4_4_ = 0;
      uStack_e0 = (longlong *)0x0;
    }
    else {
      FUN_1406e7b00(&local_e8,local_1d8);
    }
    plVar28 = uStack_e0;
    if ((logger *)local_a8._0_8_ != (logger *)0x0) {
      plVar18 = (logger *)local_a8._0_8_;
      if ((0xfff < (ulonglong)((longlong)local_98 - local_a8._0_8_)) &&
         (plVar18 = *(logger **)(local_a8._0_8_ + -8),
         (logger *)0x1f < (logger *)(local_a8._0_8_ + (-8 - (longlong)plVar18)))) {
                    /* WARNING: Subroutine does not return */
        _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
      }
      free(plVar18);
      plVar28 = uStack_e0;
    }
    plVar10 = plStack_c0;
    local_c8 = (logger *)CONCAT44(local_e8._4_4_,(undefined4)local_e8);
    local_e8._0_4_ = 0;
    local_e8._4_4_ = 0;
    uStack_e0._0_4_ = 0;
    uStack_e0._4_4_ = 0;
    if (plStack_c0 != (longlong *)0x0) {
      LOCK();
      plVar1 = plStack_c0 + 1;
      *(int *)plVar1 = (int)*plVar1 + -1;
      UNLOCK();
      if ((int)*plVar1 == 0) {
        puVar33 = (undefined8 *)*plStack_c0;
        plStack_c0 = plVar28;
        (*(code *)*puVar33)(plVar10);
        LOCK();
        piVar29 = (int *)((longlong)plVar10 + 0xc);
        *piVar29 = *piVar29 + -1;
        UNLOCK();
        plVar28 = plStack_c0;
        if (*piVar29 == 0) {
          (**(code **)(*plVar10 + 8))(plVar10);
          plVar28 = plStack_c0;
        }
      }
    }
    plStack_c0 = plVar28;
    plVar28 = (longlong *)CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
    uStack_e0 = plVar28;
    if (plVar28 != (longlong *)0x0) {
      LOCK();
      plVar10 = plVar28 + 1;
      *(int *)plVar10 = (int)*plVar10 + -1;
      UNLOCK();
      if ((int)*plVar10 == 0) {
        (**(code **)*plVar28)(plVar28);
        LOCK();
        piVar29 = (int *)((longlong)plVar28 + 0xc);
        *piVar29 = *piVar29 + -1;
        UNLOCK();
        if (*piVar29 == 0) {
          (**(code **)(*plVar28 + 8))(plVar28);
        }
      }
    }
  }
LAB_1406db5f8:
  lVar35 = param_5[2];
  local_f8 = (logger *)*param_5;
  param_5[2] = (-param_5[1] & param_5[1] + 0x13U) + lVar35;
  *(undefined8 *)((longlong)local_f8 + lVar35) = 0;
  ((undefined8 *)((longlong)local_f8 + lVar35))[1] = 0;
  *(undefined4 *)((longlong)local_f8 + 0x10 + lVar35) = 0;
  lVar17 = param_5[2];
  param_5[2] = (-param_5[1] & param_5[1] + 7U) + lVar17;
  lVar44 = *param_5;
  if (plStack_320 == (longlong *)0x0) {
    plStack_3d0 = (longlong *)0x0;
  }
  else {
    LOCK();
    *(int *)(plStack_320 + 1) = (int)plStack_320[1] + 1;
    UNLOCK();
    plStack_3d0 = plStack_320;
  }
  local_3d8 = local_328;
  FUN_1406df450(lVar44 + lVar17,&local_3d8);
  puVar2 = (uint *)((longlong)local_f8 + lVar35);
  local_a8._0_8_ = puVar2;
  uVar41 = (uint)lVar17;
  uVar41 = uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
  puVar33 = (undefined8 *)(ulonglong)uVar41;
  *puVar2 = uVar41;
  if ((longlong *)param_5[4] == (longlong *)param_5[5]) {
    FUN_1406e38e0(param_5 + 3);
  }
  else {
    *(longlong *)param_5[4] = (longlong)puVar2;
    param_5[4] = param_5[4] + 8;
  }
  uVar55 = (undefined4)((ulonglong)in_stack_fffffffffffffb38 >> 0x20);
  local_290 = (undefined8 *)lVar35;
  if ((longlong)plStack_1c0 - (longlong)local_1c8 == 0) {
    puVar2[2] = 0;
  }
  else {
    plVar18 = (logger *)((longlong)local_f8 + lVar35 + 0xc);
    lVar39 = (longlong)plStack_1c0 - (longlong)local_1c8 >> 4;
    uVar41 = (int)lVar39 * -0x55555555;
    puVar33 = (undefined8 *)param_5[2];
    lVar17 = *param_5;
    lVar44 = param_5[1];
    lVar36 = ((lVar44 + lVar39 * 0x5555555555555560) - 1U & -lVar44) + (longlong)puVar33;
    param_5[2] = ((lVar44 + lVar39 * -0x5555555555555544) - 1U & -lVar44) + lVar36;
    puVar2[2] = uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 |
                (int)lVar39 * -0x55000000;
    uVar41 = (uint)puVar33;
    puVar2[3] = uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
    if ((longlong *)param_5[4] == (longlong *)param_5[5]) {
      local_a8._0_8_ = plVar18;
      FUN_1406e38e0(param_5 + 3);
    }
    else {
      *(longlong *)param_5[4] = (longlong)plVar18;
      param_5[4] = param_5[4] + 8;
    }
    local_a8._0_8_ = (longlong)local_f8 + lVar35 + 0x10;
    uVar41 = (uint)lVar36;
    *(uint *)local_a8._0_8_ =
         uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
    if ((longlong *)param_5[4] == (longlong *)param_5[5]) {
      FUN_1406e38e0(param_5 + 3);
    }
    else {
      *(longlong *)param_5[4] = local_a8._0_8_;
      param_5[4] = param_5[4] + 8;
    }
    plVar18 = plStack_1c0;
    uVar55 = (undefined4)((ulonglong)in_stack_fffffffffffffb38 >> 0x20);
    if (local_1c8 != plStack_1c0) {
      puVar33 = (undefined8 *)((longlong)puVar33 + lVar17);
      lVar36 = lVar36 + lVar17;
      plVar19 = local_1c8;
      do {
        uVar55 = (undefined4)((ulonglong)in_stack_fffffffffffffb38 >> 0x20);
        uVar20 = *(undefined8 *)plVar19;
        uVar12 = *(undefined8 *)(plVar19 + 8);
        uVar13 = *(undefined8 *)(plVar19 + 0x18);
        puVar33[2] = *(undefined8 *)(plVar19 + 0x10);
        puVar33[3] = uVar13;
        *puVar33 = uVar20;
        puVar33[1] = uVar12;
        uVar46 = *(ushort *)(plVar19 + 0x10) << 8 | *(ushort *)(plVar19 + 0x10) >> 8;
        local_a8 = ZEXT816(0);
        local_98 = (undefined8 *)0x0;
        FUN_1406df6a0(local_b8,uVar46,local_a8);
        cVar47 = FUN_1406be9b0(plVar19);
        if (cVar47 == '\0') {
          FUN_1406df910(plVar19,local_a8);
        }
        if (*(longlong *)(plVar19 + 0x28) == 0) {
          uStack_3c0 = 0;
        }
        else {
          LOCK();
          piVar29 = (int *)(*(longlong *)(plVar19 + 0x28) + 8);
          *piVar29 = *piVar29 + 1;
          UNLOCK();
          uStack_3c0 = *(undefined8 *)(plVar19 + 0x28);
        }
        local_3c8 = *(undefined8 *)(plVar19 + 0x20);
        in_stack_fffffffffffffb38 = (logger **)CONCAT44(uVar55,(uint)uVar46);
        FUN_1406dfb70(&local_3c8,lVar36,param_5,param_6,in_stack_fffffffffffffb38,&local_288,
                      local_a8);
        if ((logger *)local_a8._0_8_ != (logger *)0x0) {
          plVar25 = (logger *)local_a8._0_8_;
          if ((0xfff < (ulonglong)((longlong)local_98 - local_a8._0_8_)) &&
             (plVar25 = *(logger **)(local_a8._0_8_ + -8),
             (logger *)0x1f < (logger *)(local_a8._0_8_ + (-8 - (longlong)plVar25)))) {
                    /* WARNING: Subroutine does not return */
            _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
          }
          free(plVar25);
        }
        uVar55 = (undefined4)((ulonglong)in_stack_fffffffffffffb38 >> 0x20);
        puVar33 = puVar33 + 4;
        lVar36 = lVar36 + 0x34;
        plVar19 = plVar19 + 0x30;
      } while (plVar19 != plVar18);
    }
  }
  puVar11 = local_290;
  if (local_c8 == (logger *)0x0) {
    uVar43 = CONCAT71((int7)((ulonglong)puVar33 >> 8),1);
  }
  else {
    lVar35 = param_5[2];
    lVar17 = *param_5;
    param_5[2] = (-param_5[1] & param_5[1] + 0x5bU) + lVar35;
    *(undefined1 (*) [16])(lVar17 + 0x4c + lVar35) = (undefined1  [16])0x0;
    *(undefined1 (*) [16])(lVar17 + 0x40 + lVar35) = (undefined1  [16])0x0;
    *(undefined1 (*) [16])(lVar17 + 0x30 + lVar35) = (undefined1  [16])0x0;
    *(undefined1 (*) [16])(lVar17 + 0x20 + lVar35) = (undefined1  [16])0x0;
    *(undefined1 (*) [16])(lVar17 + 0x10 + lVar35) = (undefined1  [16])0x0;
    *(undefined1 (*) [16])(lVar17 + lVar35) = (undefined1  [16])0x0;
    plVar28 = (longlong *)(lVar17 + 4 + lVar35);
    *plVar28 = local_1a8._0_8_;
    plVar28[1] = local_1a8._8_8_;
    puVar33 = (undefined8 *)(lVar17 + 0x14 + lVar35);
    *puVar33 = local_198._0_8_;
    puVar33[1] = local_198._8_8_;
    lVar44 = param_5[2];
    param_5[2] = (-param_5[1] & param_5[1] + 7U) + lVar44;
    lVar39 = *param_5;
    if (*(longlong *)(local_c8 + 0x18) == 0) {
      local_3b8._8_8_ = 0;
    }
    else {
      LOCK();
      piVar29 = (int *)(*(longlong *)(local_c8 + 0x18) + 8);
      *piVar29 = *piVar29 + 1;
      UNLOCK();
      local_3b8._8_8_ = *(undefined8 *)(local_c8 + 0x18);
    }
    local_3b8._0_8_ = *(undefined8 *)(local_c8 + 0x10);
    FUN_1406df450(lVar39 + lVar44,local_3b8,param_5);
    puVar2 = (uint *)(lVar17 + lVar35);
    local_a8._0_8_ = puVar2;
    uVar41 = (uint)lVar44;
    *puVar2 = uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
    plVar28 = (longlong *)param_5[4];
    if (plVar28 == (longlong *)param_5[5]) {
      FUN_1406e38e0(param_5 + 3,plVar28,local_a8);
    }
    else {
      *plVar28 = (longlong)puVar2;
      param_5[4] = param_5[4] + 8;
    }
    local_a8 = (undefined1  [16])0x0;
    local_98 = (undefined8 *)0x0;
    local_e8._0_4_ = 0x16;
    local_e8._4_4_ = (undefined4)_DAT_140771470;
    uStack_e0._0_4_ = (undefined4)((ulonglong)_DAT_140771470 >> 0x20);
    uStack_e0._4_4_ = (undefined4)_UNK_140771478;
    local_d8 = (undefined4)((ulonglong)_UNK_140771478 >> 0x20);
    puVar34 = local_a8;
    FUN_1406e3aa0(puVar34,0,&local_e8);
    local_e8._0_4_ = 0x1b;
    local_e8._4_4_ = (undefined4)_DAT_1407807d0;
    uStack_e0._0_4_ = (undefined4)((ulonglong)_DAT_1407807d0 >> 0x20);
    uStack_e0._4_4_ = (undefined4)_UNK_1407807d8;
    local_d8 = (undefined4)((ulonglong)_UNK_1407807d8 >> 0x20);
    if ((undefined8 *)local_a8._8_8_ == local_98) {
      FUN_1406e3aa0(local_a8,local_a8._8_8_,&local_e8);
    }
    else {
      *(undefined4 *)(local_a8._8_8_ + 0x10) = local_d8;
      *(ulonglong *)local_a8._8_8_ = CONCAT44(local_e8._4_4_,0x1b);
      *(ulonglong *)(local_a8._8_8_ + 8) = CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
      local_a8._8_8_ = local_a8._8_8_ + 0x14;
    }
    cVar47 = FUN_1406be9b0(local_1a8);
    if (cVar47 == '\0') {
      FUN_1406df910(local_1a8,local_a8);
    }
    if (*(longlong *)(local_c8 + 8) == 0) {
      local_3a8._8_8_ = 0;
    }
    else {
      LOCK();
      piVar29 = (int *)(*(longlong *)(local_c8 + 8) + 8);
      *piVar29 = *piVar29 + 1;
      UNLOCK();
      local_3a8._8_8_ = *(undefined8 *)(local_c8 + 8);
    }
    local_3a8._0_8_ = *(undefined8 *)local_c8;
    cVar47 = FUN_1406dfb70(local_3a8,lVar17 + lVar35 + 0x24,param_5,param_6,
                           CONCAT44(uVar55,(uint)(ushort)(local_198._0_2_ << 8 |
                                                         (ushort)local_198._0_2_ >> 8)),0,puVar34);
    if (cVar47 == '\0') {
LAB_1406dbcb4:
      if ((logger *)local_a8._0_8_ != (logger *)0x0) {
        plVar18 = (logger *)local_a8._0_8_;
        if ((0xfff < (ulonglong)((longlong)local_98 - local_a8._0_8_)) &&
           (plVar18 = *(logger **)(local_a8._0_8_ + -8),
           (logger *)0x1f < (logger *)(local_a8._0_8_ + (-8 - (longlong)plVar18)))) {
                    /* WARNING: Subroutine does not return */
          _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
        }
        free(plVar18);
      }
      uVar43 = 0;
    }
    else {
      if (*(longlong *)(local_c8 + 0x20) != 0) {
        lVar44 = param_5[2];
        lVar39 = *param_5;
        param_5[2] = (-param_5[1] & param_5[1] + 0x598fU) + lVar44;
        uVar43 = *(longlong *)(*(longlong *)(local_c8 + 0x20) + 0x30) -
                 *(longlong *)(*(longlong *)(local_c8 + 0x20) + 0x28);
        uVar41 = (uint)uVar43;
        *(uint *)(lVar39 + 0x5988 + lVar44) =
             uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
        puVar34 = (undefined1 *)(lVar39 + lVar44);
        lVar39 = param_5[2];
        param_5[2] = (-param_5[1] & ((uVar43 & 0xffffffff) + param_5[1]) - 1) + lVar39;
        if (*(longlong *)(local_c8 + 0x28) == 0) {
          local_398._8_8_ = 0;
        }
        else {
          LOCK();
          piVar29 = (int *)(*(longlong *)(local_c8 + 0x28) + 8);
          *piVar29 = *piVar29 + 1;
          UNLOCK();
          local_398._8_8_ = *(undefined8 *)(local_c8 + 0x28);
        }
        local_398._0_8_ = *(undefined8 *)(local_c8 + 0x20);
        cVar47 = FUN_1406d5540(local_1a8,local_398);
        if (cVar47 == '\0') goto LAB_1406dbcb4;
        local_e8 = (logger *)(puVar34 + 0x598c);
        uVar41 = (uint)lVar39;
        *(uint *)(puVar34 + 0x598c) =
             uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
        if ((longlong *)param_5[4] == (longlong *)param_5[5]) {
          FUN_1406e38e0(param_5 + 3);
        }
        else {
          *(longlong *)param_5[4] = (longlong)local_e8;
          param_5[4] = param_5[4] + 8;
        }
        local_e8 = (logger *)(lVar17 + lVar35 + 0x58);
        uVar41 = (uint)lVar44;
        *(uint *)local_e8 =
             uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
        if ((longlong *)param_5[4] == (longlong *)param_5[5]) {
          FUN_1406e38e0(param_5 + 3);
        }
        else {
          *(longlong *)param_5[4] = (longlong)local_e8;
          param_5[4] = param_5[4] + 8;
        }
      }
      local_e8 = (logger *)((longlong)local_f8 + (longlong)puVar11 + 4);
      uVar41 = (uint)lVar35;
      *(uint *)local_e8 =
           uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
      if ((longlong *)param_5[4] == (longlong *)param_5[5]) {
        FUN_1406e38e0(param_5 + 3);
      }
      else {
        *(longlong *)param_5[4] = (longlong)local_e8;
        param_5[4] = param_5[4] + 8;
      }
      uVar43 = CONCAT71((int7)((ulonglong)puVar34 >> 8),1);
      if ((logger *)local_a8._0_8_ != (logger *)0x0) {
        plVar18 = (logger *)local_a8._0_8_;
        if ((0xfff < (ulonglong)((longlong)local_98 - local_a8._0_8_)) &&
           (plVar18 = *(logger **)(local_a8._0_8_ + -8),
           (logger *)0x1f < (logger *)(local_a8._0_8_ + (-8 - (longlong)plVar18)))) {
                    /* WARNING: Subroutine does not return */
          _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
        }
        free(plVar18);
      }
    }
  }
  plVar28 = plStack_c0;
  if (plStack_c0 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_c0 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_c0)(plStack_c0);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar28 = plStack_2c0;
  if (plStack_2c0 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_2c0 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_2c0)(plStack_2c0);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar28 = plStack_2d0;
  if (plStack_2d0 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_2d0 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_2d0)(plStack_2d0);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar28 = plStack_2e0;
  if (plStack_2e0 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_2e0 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_2e0)(plStack_2e0);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar28 = plStack_2f0;
  if (plStack_2f0 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_2f0 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_2f0)(plStack_2f0);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar28 = plStack_300;
  if (plStack_300 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_300 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_300)(plStack_300);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar18 = plStack_310;
  if (plStack_310 != (logger *)0x0) {
    LOCK();
    plVar19 = plStack_310 + 8;
    *(int *)plVar19 = *(int *)plVar19 + -1;
    UNLOCK();
    if (*(int *)plVar19 == 0) {
      (*(code *)**(undefined8 **)plStack_310)(plStack_310);
      LOCK();
      plVar19 = plVar18 + 0xc;
      *(int *)plVar19 = *(int *)plVar19 + -1;
      UNLOCK();
      if (*(int *)plVar19 == 0) {
        (**(code **)(*(longlong *)plVar18 + 8))(plVar18);
      }
    }
  }
  plVar28 = plStack_230;
  if (plStack_230 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_230 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_230)(plStack_230);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar28 = plStack_240;
  if (plStack_240 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_240 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_240)(plStack_240);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar28 = plStack_250;
  if (plStack_250 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_250 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_250)(plStack_250);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  plVar28 = plStack_260;
  if (plStack_260 != (longlong *)0x0) {
    LOCK();
    plVar10 = plStack_260 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*plStack_260)(plStack_260);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  uVar20 = local_278._8_8_;
  if ((longlong *)local_278._8_8_ != (longlong *)0x0) {
    LOCK();
    plVar28 = (longlong *)(local_278._8_8_ + 8);
    *(int *)plVar28 = (int)*plVar28 + -1;
    UNLOCK();
    if ((int)*plVar28 == 0) {
      (*(code *)**(undefined8 **)local_278._8_8_)(local_278._8_8_);
      LOCK();
      piVar29 = (int *)(uVar20 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*(longlong *)uVar20 + 8))(uVar20);
      }
    }
  }
  plVar28 = uStack_280;
  if (uStack_280 != (longlong *)0x0) {
    LOCK();
    plVar10 = uStack_280 + 1;
    *(int *)plVar10 = (int)*plVar10 + -1;
    UNLOCK();
    if ((int)*plVar10 == 0) {
      (**(code **)*uStack_280)(uStack_280);
      LOCK();
      piVar29 = (int *)((longlong)plVar28 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plVar28 + 8))(plVar28);
      }
    }
  }
  FUN_1406e4160(&local_1c8);
  if ((void *)local_2a8._0_8_ != (void *)0x0) {
    pvVar26 = (void *)local_2a8._0_8_;
    if ((0xfff < (ulonglong)((longlong)local_298 - local_2a8._0_8_)) &&
       (pvVar26 = *(void **)(local_2a8._0_8_ + -8),
       0x1f < (ulonglong)(local_2a8._0_8_ + (-8 - (longlong)pvVar26)))) {
                    /* WARNING: Subroutine does not return */
      _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
    }
    free(pvVar26);
  }
  FUN_1406e4270(&local_1f8);
joined_r0x0001406d749a:
  if (plStack_320 != (longlong *)0x0) {
    LOCK();
    plVar28 = plStack_320 + 1;
    *(int *)plVar28 = (int)*plVar28 + -1;
    UNLOCK();
    if ((int)*plVar28 == 0) {
      (**(code **)*plStack_320)(plStack_320);
      LOCK();
      piVar29 = (int *)((longlong)plStack_320 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*plStack_320 + 8))(plStack_320);
      }
    }
  }
  return uVar43 & 0xffffffff;
LAB_1406d7b74:
  for (; plVar19 != (logger *)uVar20; plVar19 = plVar19 + 0x20) {
    local_1a8 = ZEXT816(0);
    if ((((*(uint *)plVar19 != 0) || (*(short *)(plVar19 + 4) != 0)) ||
        ((*(short *)(plVar19 + 6) != 0 ||
         (plVar18 = *(logger **)(plVar19 + 8), plVar18 != (logger *)0x0)))) &&
       ((((byte)plVar19[0x11] & 4) != 0 &&
        (plVar18 = (logger *)FUN_1406be9b0(plVar19), (char)plVar18 != '\0')))) {
      uVar46 = *(ushort *)(plVar19 + 4);
      plVar18 = (logger *)(ulonglong)uVar46;
      uVar43 = (ulonglong)(ushort)(uVar46 << 8 | uVar46 >> 8);
      lVar35 = *(longlong *)(local_f0 + 0x20);
      uVar27 = (*(longlong *)(local_f0 + 0x28) - lVar35 >> 3) * -0x7b425ed097b425ed;
      if (uVar43 < uVar27) {
        lVar17 = uVar43 * 0xd8;
        uVar8 = *(ushort *)(lVar35 + 0xa0 + lVar17);
        local_1a8 = ZEXT816(0);
        bVar48 = false;
        if (((*(int *)(lVar35 + 0x9c + lVar17) == 0) && (uVar8 == 0)) &&
           (*(short *)(lVar35 + 0xa2 + lVar17) == 0)) {
          bVar48 = *(longlong *)(lVar35 + lVar17 + 0xa4) == 0;
        }
        if ((((ushort)(uVar8 << 8 | uVar8 >> 8) < uVar27) && (uVar8 != uVar46)) && (!bVar48)) {
          *(ushort *)(plVar19 + 4) = uVar8;
        }
      }
    }
  }
  plVar19 = (logger *)local_2a8._8_8_;
LAB_1406d7c82:
  for (plVar25 = (logger *)local_2a8._0_8_; plVar25 != plVar19; plVar25 = plVar25 + 0x20) {
    while (cVar47 = FUN_1406be9b0(plVar25), cVar47 == '\0') {
      local_318 = (logger *)0x0;
      plStack_310 = (logger *)0x0;
      local_308 = 0;
      uVar20 = FUN_1406cb380();
      plVar18 = (logger *)FUN_1406c71f0(uVar20,plVar25);
      if (((char)plVar18 != '\0') && (local_318 != plStack_310)) {
        plVar21 = (logger *)FUN_1406eb780(local_318,(longlong)plStack_310 - (longlong)local_318);
        plVar18 = plVar21;
        for (local_1c8 = (logger *)0x0; local_1c8 < plVar21; local_1c8 = local_1c8 + 1) {
          local_c8 = (logger *)0x0;
          local_1d8 = (undefined *)0x0;
          in_stack_fffffffffffffb38 = &local_c8;
          plVar18 = (logger *)
                    FUN_1406eb3e0(local_318,(longlong)plStack_310 - (longlong)local_318,4,local_1c8,
                                  &local_c8,&local_1d8);
          if ((char)plVar18 == '\0') break;
          FUN_1406bb040(&local_e8,local_c8,local_1d8,local_ac);
          uVar43 = CONCAT44(local_e8._4_4_,(undefined4)local_e8);
          if (uVar43 == 0) {
            if ((*(int *)(*(longlong *)
                           ((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8) + 0x9c)
                 < DAT_140809d78) && (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
              rex::RegisterLogCategory((char *)&DAT_140809d74);
              _Init_thread_footer(&DAT_140809d78);
            }
            plVar18 = rex::GetLoggerRaw(DAT_140809d74);
            auVar49 = local_198;
            if ((plVar18 != (logger *)0x0) && (*(int *)(plVar18 + 0x40) < 4)) {
              uVar41 = *(uint *)plVar25;
              local_1a8._0_4_ =
                   uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 |
                   uVar41 << 0x18;
              local_198._2_2_ = 0;
              local_198._0_2_ = *(ushort *)(plVar25 + 4) << 8 | *(ushort *)(plVar25 + 4) >> 8;
              local_198._4_12_ = auVar49._4_12_;
              local_188 = (longlong *)
                          CONCAT44(local_188._4_4_,
                                   (uint)(ushort)(*(ushort *)(plVar25 + 6) << 8 |
                                                 *(ushort *)(plVar25 + 6) >> 8));
              local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)plVar25[8]);
              local_168 = (uint)(byte)plVar25[9];
              local_158 = (uint)(byte)plVar25[10];
              local_148 = (uint)(byte)plVar25[0xb];
              local_138 = (uint)(byte)plVar25[0xc];
              local_128 = (uint)(byte)plVar25[0xd];
              local_118 = (uint)(byte)plVar25[0xe];
              local_108 = (uint)(byte)plVar25[0xf];
              lStack_220 = (longlong)local_1a8;
              local_228 = (undefined1  [8])0x22222222222;
              local_a8._8_8_ = 0x46;
              local_a8._0_8_ = &DAT_140776223;
              FUN_140729480(&local_288,local_a8,local_228);
              lStack_220 = 0x43;
              local_228 = (undefined1  [8])
                          "[avatar] failed to load embedded hiding shape {} for closet item {}";
              local_1a8._8_4_ = 0x38a;
              local_1a8._0_8_ =
                   "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
              ;
              local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
              in_stack_fffffffffffffb38 = &local_1c8;
              FUN_1406e4380(plVar18,local_1a8,3,local_228,in_stack_fffffffffffffb38,&local_288);
              plVar18 = (logger *)local_278._8_8_;
              if ((logger *)0xf < (ulonglong)local_278._8_8_) {
                plVar18 = local_288;
                if (((logger *)0xfff < (logger *)(local_278._8_8_ + 1)) &&
                   (plVar18 = *(logger **)(local_288 + -8),
                   (logger *)0x1f < local_288 + (-8 - (longlong)plVar18))) {
                    /* WARNING: Subroutine does not return */
                  _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
                }
                free(plVar18);
                plVar18 = extraout_RAX;
              }
            }
          }
          else {
            if (*(int *)(uVar43 + 4) == 0x2000000) {
              *(undefined2 *)(uVar43 + 8) = 0;
            }
            if (*(int *)(uVar43 + 0x34) == 0x2000000) {
              *(undefined2 *)(uVar43 + 0x38) = 0;
            }
            local_1a8 = *(undefined1 (*) [16])plVar25;
            if (CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) == 0) {
              local_198._8_8_ = 0;
              local_198._0_8_ = uVar43;
            }
            else {
              LOCK();
              piVar29 = (int *)(CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) + 8);
              *piVar29 = *piVar29 + 1;
              UNLOCK();
              local_198._4_4_ = local_e8._4_4_;
              local_198._0_4_ = (undefined4)local_e8;
              local_198._12_4_ = uStack_e0._4_4_;
              local_198._8_4_ = (undefined4)uStack_e0;
            }
            if (puStack_1f0 == local_1e8) {
              plVar18 = (logger *)FUN_1406e1250(&local_1f8);
              uVar20 = local_198._8_8_;
              if ((longlong *)local_198._8_8_ != (longlong *)0x0) {
                LOCK();
                plVar28 = (longlong *)(local_198._8_8_ + 8);
                *(int *)plVar28 = (int)*plVar28 + -1;
                UNLOCK();
                if ((int)*plVar28 == 0) {
                  plVar18 = (logger *)(*(code *)**(undefined8 **)local_198._8_8_)(local_198._8_8_);
                  LOCK();
                  piVar29 = (int *)(uVar20 + 0xc);
                  *piVar29 = *piVar29 + -1;
                  UNLOCK();
                  if (*piVar29 == 0) {
                    plVar18 = (logger *)(**(code **)(*(longlong *)uVar20 + 8))(uVar20);
                  }
                }
              }
            }
            else {
              *(undefined8 *)puStack_1f0 = local_1a8._0_8_;
              *(undefined8 *)(puStack_1f0 + 2) = local_1a8._8_8_;
              puStack_1f0[4] = 0;
              puStack_1f0[5] = 0;
              puStack_1f0[6] = 0;
              puStack_1f0[7] = 0;
              *(undefined8 *)(puStack_1f0 + 4) = local_198._0_8_;
              *(undefined8 *)(puStack_1f0 + 6) = local_198._8_8_;
              puStack_1f0 = puStack_1f0 + 8;
              plVar18 = (logger *)local_198._8_8_;
            }
          }
          plVar28 = (longlong *)CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
          if (plVar28 != (longlong *)0x0) {
            LOCK();
            plVar10 = plVar28 + 1;
            *(int *)plVar10 = (int)*plVar10 + -1;
            UNLOCK();
            if ((int)*plVar10 == 0) {
              plVar18 = (logger *)(**(code **)*plVar28)(plVar28);
              LOCK();
              piVar29 = (int *)((longlong)plVar28 + 0xc);
              *piVar29 = *piVar29 + -1;
              UNLOCK();
              if (*piVar29 == 0) {
                plVar18 = (logger *)(**(code **)(*plVar28 + 8))(plVar28);
              }
            }
          }
        }
      }
      if (local_318 == (logger *)0x0) goto LAB_1406d9000;
      plVar18 = local_318;
      if ((0xfff < (ulonglong)(local_308 - (longlong)local_318)) &&
         (plVar18 = *(logger **)(local_318 + -8),
         (logger *)0x1f < local_318 + (-8 - (longlong)plVar18))) {
                    /* WARNING: Subroutine does not return */
        _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
      }
      free(plVar18);
      plVar25 = plVar25 + 0x20;
      plVar18 = extraout_RAX_00;
      if (plVar25 == plVar19) goto LAB_1406d7ca3;
    }
    uVar27 = (ulonglong)(ushort)(*(ushort *)(plVar25 + 4) << 8 | *(ushort *)(plVar25 + 4) >> 8);
    plVar21 = *(logger **)(local_f0 + 0x20);
    uVar43 = (*(longlong *)(local_f0 + 0x28) - (longlong)plVar21 >> 3) * -0x7b425ed097b425ed;
    plVar18 = plVar21;
    if (((uVar27 < uVar43) && (lVar35 = uVar27 * 0xd8, *(int *)(plVar21 + lVar35 + 0x9c) == 1)) &&
       ((ushort)(*(ushort *)(plVar21 + lVar35 + 0xa0) << 8 |
                *(ushort *)(plVar21 + lVar35 + 0xa0) >> 8) < uVar43)) {
      FUN_1406ddd60(&local_e8,local_f0);
      if (CONCAT44(local_e8._4_4_,(undefined4)local_e8) == 0) {
        if ((*(int *)(*(longlong *)((longlong)ThreadLocalStoragePointer + (ulonglong)_tls_index * 8)
                     + 0x9c) < DAT_140809d78) &&
           (FUN_14074767c(&DAT_140809d78), DAT_140809d78 == -1)) {
          rex::RegisterLogCategory((char *)&DAT_140809d74);
          _Init_thread_footer(&DAT_140809d78);
        }
        plVar22 = rex::GetLoggerRaw(DAT_140809d74);
        plVar18 = (logger *)0x0;
        if ((plVar22 != (logger *)0x0) &&
           (plVar18 = (logger *)(ulonglong)*(uint *)(plVar22 + 0x40),
           (int)*(uint *)(plVar22 + 0x40) < 4)) {
          uVar41 = *(uint *)plVar25;
          local_168 = (uint)(byte)plVar25[9];
          local_158 = (uint)(byte)plVar25[10];
          local_148 = (uint)(byte)plVar25[0xb];
          local_138 = (uint)(byte)plVar25[0xc];
          local_128 = (uint)(byte)plVar25[0xd];
          local_118 = (uint)(byte)plVar25[0xe];
          local_108 = (uint)(byte)plVar25[0xf];
          local_318 = (logger *)0x22222222222;
          plStack_310 = (logger *)local_1a8;
          local_228 = (undefined1  [8])&DAT_140776223;
          lStack_220 = 0x46;
          local_1a8._0_4_ =
               uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
          local_198._0_4_ =
               (uint)(ushort)(*(ushort *)(plVar25 + 4) << 8 | *(ushort *)(plVar25 + 4) >> 8);
          local_188._0_4_ =
               (uint)(ushort)(*(ushort *)(plVar25 + 6) << 8 | *(ushort *)(plVar25 + 6) >> 8);
          local_178._0_4_ = (uint)(byte)plVar25[8];
          FUN_140729480(&local_288,local_228,&local_318);
          uVar41 = *(uint *)(plVar21 + lVar35 + 0x9c);
          local_1a8._0_4_ =
               uVar41 >> 0x18 | (uVar41 & 0xff0000) >> 8 | (uVar41 & 0xff00) << 8 | uVar41 << 0x18;
          local_198._2_2_ = 0;
          local_198._0_2_ =
               *(ushort *)(plVar21 + lVar35 + 0xa0) << 8 | *(ushort *)(plVar21 + lVar35 + 0xa0) >> 8
          ;
          local_188 = (longlong *)
                      CONCAT44(local_188._4_4_,
                               (uint)(ushort)(*(ushort *)(plVar21 + lVar35 + 0xa2) << 8 |
                                             *(ushort *)(plVar21 + lVar35 + 0xa2) >> 8));
          local_178 = (logger *)CONCAT44(local_178._4_4_,(uint)(byte)plVar21[lVar35 + 0xa4]);
          local_168 = (uint)(byte)plVar21[lVar35 + 0xa5];
          local_158 = (uint)(byte)plVar21[lVar35 + 0xa6];
          local_148 = (uint)(byte)plVar21[lVar35 + 0xa7];
          local_138 = (uint)(byte)plVar21[lVar35 + 0xa8];
          local_128 = (uint)(byte)plVar21[lVar35 + 0xa9];
          local_118 = (uint)(byte)plVar21[lVar35 + 0xaa];
          local_108 = (uint)(byte)plVar21[lVar35 + 0xab];
          lStack_220 = (longlong)local_1a8;
          local_228 = (undefined1  [8])0x22222222222;
          local_a8._8_8_ = 0x46;
          local_a8._0_8_ = &DAT_140776223;
          in_stack_fffffffffffffb38 = &local_318;
          FUN_140729480(in_stack_fffffffffffffb38,local_a8,local_228);
          lStack_220 = 0x38;
          local_228 = (undefined1  [8])"[avatar] failed to load hiding shape {} for component {}";
          local_1a8._8_4_ = 0x3a5;
          local_1a8._0_8_ =
               "C:/Users/vigln/OneDrive/Desktop/Series XS Ports/NXE/avatar_editor_7357/src/kernel/xam/avatars/guest_load_asset.cpp"
          ;
          local_198._0_8_ = "rex::avatars::LoadAssetsToGuest";
          FUN_1406e4790(plVar22,local_1a8,3,local_228,in_stack_fffffffffffffb38,&local_288);
          if ((longlong *)0xf < plStack_300) {
            plVar18 = local_318;
            if ((0xfff < (longlong)plStack_300 + 1U) &&
               (plVar18 = *(logger **)(local_318 + -8),
               (logger *)0x1f < local_318 + (-8 - (longlong)plVar18))) {
                    /* WARNING: Subroutine does not return */
              _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
            }
            free(plVar18);
          }
          plVar18 = (logger *)local_278._8_8_;
          if ((logger *)0xf < (ulonglong)local_278._8_8_) {
            plVar18 = local_288;
            if (((logger *)0xfff < (logger *)(local_278._8_8_ + 1)) &&
               (plVar18 = *(logger **)(local_288 + -8),
               (logger *)0x1f < local_288 + (-8 - (longlong)plVar18))) {
                    /* WARNING: Subroutine does not return */
              _invoke_watson((wchar_t *)0x0,(wchar_t *)0x0,(wchar_t *)0x0,0,0);
            }
            free(plVar18);
            plVar18 = extraout_RAX_01;
          }
        }
      }
      else {
        local_1a8 = *(undefined1 (*) [16])(plVar21 + lVar35 + 0x9c);
        if (CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) == 0) {
          local_198._8_8_ = 0;
          local_198._0_8_ = CONCAT44(local_e8._4_4_,(undefined4)local_e8);
        }
        else {
          LOCK();
          piVar29 = (int *)(CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0) + 8);
          *piVar29 = *piVar29 + 1;
          UNLOCK();
          local_198._4_4_ = local_e8._4_4_;
          local_198._0_4_ = (undefined4)local_e8;
          local_198._12_4_ = uStack_e0._4_4_;
          local_198._8_4_ = (undefined4)uStack_e0;
        }
        if (puStack_1f0 == local_1e8) {
          plVar18 = (logger *)FUN_1406e1250(&local_1f8);
          uVar20 = local_198._8_8_;
          if ((longlong *)local_198._8_8_ != (longlong *)0x0) {
            LOCK();
            plVar28 = (longlong *)(local_198._8_8_ + 8);
            *(int *)plVar28 = (int)*plVar28 + -1;
            UNLOCK();
            if ((int)*plVar28 == 0) {
              plVar18 = (logger *)(*(code *)**(undefined8 **)local_198._8_8_)(local_198._8_8_);
              LOCK();
              piVar29 = (int *)(uVar20 + 0xc);
              *piVar29 = *piVar29 + -1;
              UNLOCK();
              if (*piVar29 == 0) {
                plVar18 = (logger *)(**(code **)(*(longlong *)uVar20 + 8))(uVar20);
              }
            }
          }
        }
        else {
          *(undefined8 *)puStack_1f0 = local_1a8._0_8_;
          *(undefined8 *)(puStack_1f0 + 2) = local_1a8._8_8_;
          puStack_1f0[4] = 0;
          puStack_1f0[5] = 0;
          puStack_1f0[6] = 0;
          puStack_1f0[7] = 0;
          *(undefined8 *)(puStack_1f0 + 4) = local_198._0_8_;
          *(undefined8 *)(puStack_1f0 + 6) = local_198._8_8_;
          puStack_1f0 = puStack_1f0 + 8;
          plVar18 = (logger *)local_198._8_8_;
        }
      }
      plVar28 = (longlong *)CONCAT44(uStack_e0._4_4_,(undefined4)uStack_e0);
      if (plVar28 != (longlong *)0x0) {
        LOCK();
        plVar10 = plVar28 + 1;
        *(int *)plVar10 = (int)*plVar10 + -1;
        UNLOCK();
        if ((int)*plVar10 == 0) {
          plVar18 = (logger *)(**(code **)*plVar28)(plVar28);
          LOCK();
          piVar29 = (int *)((longlong)plVar28 + 0xc);
          *piVar29 = *piVar29 + -1;
          UNLOCK();
          if (*piVar29 == 0) {
            plVar18 = (logger *)(**(code **)(*plVar28 + 8))(plVar28);
          }
        }
      }
    }
LAB_1406d9000:
  }
LAB_1406d7ca3:
  local_2b0 = CONCAT44(local_2b0._4_4_,(int)CONCAT71((int7)((ulonglong)plVar18 >> 8),1));
  plVar18 = (logger *)local_2a8._8_8_;
  goto LAB_1406d7cb9;
  while (plVar18 = plVar18 + 0x30, plVar18 != plStack_1c0) {
LAB_1406d9c9d:
    if ((((*(uint *)plVar18 == *puVar30) && (*(short *)(plVar18 + 4) == (short)puVar30[1])) &&
        (*(short *)(plVar18 + 6) == *(short *)((longlong)puVar30 + 6))) &&
       (*(longlong *)(plVar18 + 8) == *(longlong *)(puVar30 + 2))) {
      if (*(longlong *)(plVar18 + 0x28) == 0) {
        local_a8._8_8_ = 0;
        local_a8._0_8_ = *(ulonglong *)(plVar18 + 0x20);
      }
      else {
        LOCK();
        piVar29 = (int *)(*(longlong *)(plVar18 + 0x28) + 8);
        *piVar29 = *piVar29 + 1;
        UNLOCK();
        local_a8 = *(undefined1 (*) [16])(plVar18 + 0x20);
      }
      break;
    }
  }
LAB_1406d9d20:
  uVar46 = *(ushort *)(*(longlong *)(puVar30 + 4) + 0x3a) << 8 |
           *(ushort *)(*(longlong *)(puVar30 + 4) + 0x3a) >> 8;
  auVar49 = local_a8;
  if (((ushort)(uVar46 - 3) < 0xfffe) || (DAT_14080b110 == 0)) {
    local_368 = 0;
    uStack_360 = 0;
  }
  else {
    uVar43 = (ulonglong)uVar46;
    plVar28 = (longlong *)(&DAT_14080b0e0 + uVar43 * 0x10);
    if ((*(longlong *)(&DAT_14080b0e0 + uVar43 * 0x10) == 0) ||
       (*(uint *)((longlong)&DAT_14080b150 + (ulonglong)uVar46 * 4 + 4) != local_ac)) {
      plVar10 = *(longlong **)(&DAT_14080b0e8 + uVar43 * 4);
      *plVar28 = 0;
      *(undefined8 *)(&DAT_14080b0e8 + uVar43 * 4) = 0;
      if (plVar10 != (longlong *)0x0) {
        LOCK();
        plVar1 = plVar10 + 1;
        *(int *)plVar1 = (int)*plVar1 + -1;
        UNLOCK();
        if ((int)*plVar1 == 0) {
          (**(code **)*plVar10)(plVar10);
          LOCK();
          piVar29 = (int *)((longlong)plVar10 + 0xc);
          *piVar29 = *piVar29 + -1;
          UNLOCK();
          if (*piVar29 == 0) {
            (**(code **)(*plVar10 + 8))(plVar10);
          }
        }
      }
      lVar35 = *(longlong *)(DAT_14080b110 + 0x28) - *(longlong *)(DAT_14080b110 + 0x20);
      if (lVar35 != 0) {
        pbVar23 = (byte *)(*(longlong *)(DAT_14080b110 + 0x20) + 4);
        lVar17 = 0;
        do {
          if (((pbVar23[-4] & 2) != 0) && (uVar46 == *pbVar23)) {
            local_e8._0_4_ = 0;
            local_e8._4_4_ = 0;
            local_c8 = (logger *)0x0;
            cVar47 = FUN_1406b9ee0(DAT_14080b110,lVar17,&local_e8,&local_c8);
            if (cVar47 != '\0') {
              FUN_1406e5f50(local_1a8,CONCAT44(local_e8._4_4_,(undefined4)local_e8),local_c8,
                            local_ac);
              lVar35 = local_1a8._0_8_;
              uVar20 = local_1a8._8_8_;
              local_1a8 = ZEXT816(0);
              plVar10 = *(longlong **)(&DAT_14080b0e8 + uVar43 * 4);
              *plVar28 = lVar35;
              *(undefined8 *)(&DAT_14080b0e8 + uVar43 * 4) = uVar20;
              if (plVar10 != (longlong *)0x0) {
                LOCK();
                plVar1 = plVar10 + 1;
                *(int *)plVar1 = (int)*plVar1 + -1;
                UNLOCK();
                if ((int)*plVar1 == 0) {
                  (**(code **)*plVar10)(plVar10);
                  LOCK();
                  piVar29 = (int *)((longlong)plVar10 + 0xc);
                  *piVar29 = *piVar29 + -1;
                  UNLOCK();
                  if (*piVar29 == 0) {
                    (**(code **)(*plVar10 + 8))(plVar10);
                  }
                }
                uVar20 = local_1a8._8_8_;
                if ((longlong *)local_1a8._8_8_ != (longlong *)0x0) {
                  LOCK();
                  plVar10 = (longlong *)(local_1a8._8_8_ + 8);
                  *(int *)plVar10 = (int)*plVar10 + -1;
                  UNLOCK();
                  if ((int)*plVar10 == 0) {
                    (*(code *)**(undefined8 **)local_1a8._8_8_)(local_1a8._8_8_);
                    LOCK();
                    piVar29 = (int *)(uVar20 + 0xc);
                    *piVar29 = *piVar29 + -1;
                    UNLOCK();
                    if (*piVar29 == 0) {
                      (**(code **)(*(longlong *)uVar20 + 8))(uVar20);
                    }
                  }
                }
                lVar35 = *plVar28;
              }
              if (lVar35 != 0) {
                *(uint *)((longlong)&DAT_14080b150 + (ulonglong)uVar46 * 4 + 4) = local_ac;
              }
            }
            break;
          }
          lVar17 = lVar17 + 1;
          pbVar23 = pbVar23 + 0xd8;
        } while ((lVar35 >> 3) * -0x7b425ed097b425ed != lVar17);
      }
      if (*(longlong *)(&DAT_14080b0e8 + uVar43 * 4) == 0) {
        uStack_360 = 0;
      }
      else {
        LOCK();
        piVar29 = (int *)(*(longlong *)(&DAT_14080b0e8 + uVar43 * 4) + 8);
        *piVar29 = *piVar29 + 1;
        UNLOCK();
        uStack_360 = *(undefined8 *)(&DAT_14080b0e8 + uVar43 * 4);
      }
      local_368 = *plVar28;
      auVar49 = local_a8;
    }
    else if (*(longlong *)(&DAT_14080b0e8 + uVar43 * 4) == 0) {
      uStack_360 = 0;
      local_368 = *(longlong *)(&DAT_14080b0e0 + uVar43 * 0x10);
    }
    else {
      LOCK();
      piVar29 = (int *)(*(longlong *)(&DAT_14080b0e8 + uVar43 * 4) + 8);
      *piVar29 = *piVar29 + 1;
      UNLOCK();
      uStack_360 = *(undefined8 *)(&DAT_14080b0e8 + uVar43 * 4);
      local_368 = *plVar28;
    }
  }
  if (local_a8._8_8_ == 0) {
    local_a8._8_8_ = 0;
  }
  else {
    LOCK();
    *(int *)(local_a8._8_8_ + 8) = *(int *)(local_a8._8_8_ + 8) + 1;
    UNLOCK();
    local_a8._8_8_ = auVar49._8_8_;
  }
  local_a8._0_8_ = auVar49._0_8_;
  local_418 = (logger *)local_a8._0_8_;
  if (*(longlong *)(plVar19 + 0x28) == 0) {
    uStack_400 = 0;
  }
  else {
    LOCK();
    piVar29 = (int *)(*(longlong *)(plVar19 + 0x28) + 8);
    *piVar29 = *piVar29 + 1;
    UNLOCK();
    uStack_400 = *(undefined8 *)(plVar19 + 0x28);
  }
  local_408 = *(undefined8 *)(plVar19 + 0x20);
  if (*(longlong *)(puVar30 + 6) == 0) {
    uStack_3f0 = 0;
  }
  else {
    LOCK();
    piVar29 = (int *)(*(longlong *)(puVar30 + 6) + 8);
    *piVar29 = *piVar29 + 1;
    UNLOCK();
    uStack_3f0 = *(undefined8 *)(puVar30 + 6);
  }
  local_3f8 = *(undefined8 *)(puVar30 + 4);
  uStack_410 = local_a8._8_8_;
  local_a8 = auVar49;
  FUN_1406bbcc0(&local_3f8,&local_408);
  uVar20 = local_a8._8_8_;
  if ((longlong *)local_a8._8_8_ != (longlong *)0x0) {
    LOCK();
    plVar28 = (longlong *)(local_a8._8_8_ + 8);
    *(int *)plVar28 = (int)*plVar28 + -1;
    UNLOCK();
    if ((int)*plVar28 == 0) {
      (*(code *)**(undefined8 **)local_a8._8_8_)(local_a8._8_8_);
      LOCK();
      piVar29 = (int *)(uVar20 + 0xc);
      *piVar29 = *piVar29 + -1;
      UNLOCK();
      if (*piVar29 == 0) {
        (**(code **)(*(longlong *)uVar20 + 8))(uVar20);
      }
    }
  }
LAB_1406d9c07:
  puVar30 = puVar30 + 8;
  goto LAB_1406d9c0b;
}

