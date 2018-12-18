//===- AMDGPURegisterBankInfo.cpp -------------------------------*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
/// This file implements the targeting of the RegisterBankInfo class for
/// AMDGPU.
/// \todo This should be generated by TableGen.
//===----------------------------------------------------------------------===//

#include "AMDGPURegisterBankInfo.h"
#include "AMDGPUInstrInfo.h"
#include "SIMachineFunctionInfo.h"
#include "SIRegisterInfo.h"
#include "MCTargetDesc/AMDGPUMCTargetDesc.h"
#include "llvm/CodeGen/GlobalISel/RegisterBank.h"
#include "llvm/CodeGen/GlobalISel/RegisterBankInfo.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/IR/Constants.h"

#define GET_TARGET_REGBANK_IMPL
#include "AMDGPUGenRegisterBank.inc"

// This file will be TableGen'ed at some point.
#include "AMDGPUGenRegisterBankInfo.def"

using namespace llvm;

AMDGPURegisterBankInfo::AMDGPURegisterBankInfo(const TargetRegisterInfo &TRI)
    : AMDGPUGenRegisterBankInfo(),
      TRI(static_cast<const SIRegisterInfo*>(&TRI)) {

  // HACK: Until this is fully tablegen'd.
  static bool AlreadyInit = false;
  if (AlreadyInit)
    return;

  AlreadyInit = true;

  const RegisterBank &RBSGPR = getRegBank(AMDGPU::SGPRRegBankID);
  (void)RBSGPR;
  assert(&RBSGPR == &AMDGPU::SGPRRegBank);

  const RegisterBank &RBVGPR = getRegBank(AMDGPU::VGPRRegBankID);
  (void)RBVGPR;
  assert(&RBVGPR == &AMDGPU::VGPRRegBank);

}

static bool isConstant(const MachineOperand &MO, int64_t &C) {
  const MachineFunction *MF = MO.getParent()->getParent()->getParent();
  const MachineRegisterInfo &MRI = MF->getRegInfo();
  const MachineInstr *Def = MRI.getVRegDef(MO.getReg());
  if (!Def)
    return false;

  if (Def->getOpcode() == AMDGPU::G_CONSTANT) {
    C = Def->getOperand(1).getCImm()->getSExtValue();
    return true;
  }

  if (Def->getOpcode() == AMDGPU::COPY)
    return isConstant(Def->getOperand(1), C);

  return false;
}

unsigned AMDGPURegisterBankInfo::copyCost(const RegisterBank &Dst,
                                          const RegisterBank &Src,
                                          unsigned Size) const {
  if (Dst.getID() == AMDGPU::SGPRRegBankID &&
      Src.getID() == AMDGPU::VGPRRegBankID)
    return std::numeric_limits<unsigned>::max();

  // SGPRRegBank with size 1 is actually vcc or another 64-bit sgpr written by
  // the valu.
  if (Size == 1 && Dst.getID() == AMDGPU::SCCRegBankID &&
      Src.getID() == AMDGPU::SGPRRegBankID)
    return std::numeric_limits<unsigned>::max();

  return RegisterBankInfo::copyCost(Dst, Src, Size);
}

const RegisterBank &AMDGPURegisterBankInfo::getRegBankFromRegClass(
    const TargetRegisterClass &RC) const {

  if (TRI->isSGPRClass(&RC))
    return getRegBank(AMDGPU::SGPRRegBankID);

  return getRegBank(AMDGPU::VGPRRegBankID);
}

RegisterBankInfo::InstructionMappings
AMDGPURegisterBankInfo::getInstrAlternativeMappings(
    const MachineInstr &MI) const {

  const MachineFunction &MF = *MI.getParent()->getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();


  InstructionMappings AltMappings;
  switch (MI.getOpcode()) {
  case TargetOpcode::G_LOAD: {
    unsigned Size = getSizeInBits(MI.getOperand(0).getReg(), MRI, *TRI);
    // FIXME: Should we be hard coding the size for these mappings?
    const InstructionMapping &SSMapping = getInstructionMapping(
        1, 1, getOperandsMapping(
                  {AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size),
                   AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 64)}),
        2); // Num Operands
    AltMappings.push_back(&SSMapping);

    const InstructionMapping &VVMapping = getInstructionMapping(
        2, 1, getOperandsMapping(
                  {AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                   AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 64)}),
        2); // Num Operands
    AltMappings.push_back(&VVMapping);

    // FIXME: Should this be the pointer-size (64-bits) or the size of the
    // register that will hold the bufffer resourc (128-bits).
    const InstructionMapping &VSMapping = getInstructionMapping(
        3, 1, getOperandsMapping(
                  {AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                   AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 64)}),
        2); // Num Operands
    AltMappings.push_back(&VSMapping);

    return AltMappings;

  }
  case TargetOpcode::G_ICMP: {
    unsigned Size = getSizeInBits(MI.getOperand(2).getReg(), MRI, *TRI);
    const InstructionMapping &SSMapping = getInstructionMapping(1, 1,
      getOperandsMapping({AMDGPU::getValueMapping(AMDGPU::SCCRegBankID, 1),
                          nullptr, // Predicate operand.
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size)}),
      4); // Num Operands
    AltMappings.push_back(&SSMapping);

    const InstructionMapping &SVMapping = getInstructionMapping(2, 1,
      getOperandsMapping({AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 1),
                          nullptr, // Predicate operand.
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size)}),
      4); // Num Operands
    AltMappings.push_back(&SVMapping);

    const InstructionMapping &VSMapping = getInstructionMapping(3, 1,
      getOperandsMapping({AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 1),
                          nullptr, // Predicate operand.
                          AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size)}),
      4); // Num Operands
    AltMappings.push_back(&VSMapping);

    const InstructionMapping &VVMapping = getInstructionMapping(4, 1,
      getOperandsMapping({AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 1),
                          nullptr, // Predicate operand.
                          AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size)}),
      4); // Num Operands
    AltMappings.push_back(&VVMapping);

    return AltMappings;
  }
  case TargetOpcode::G_SELECT: {
    unsigned Size = getSizeInBits(MI.getOperand(0).getReg(), MRI, *TRI);
    const InstructionMapping &SSMapping = getInstructionMapping(1, 1,
      getOperandsMapping({AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::SCCRegBankID, 1),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size)}),
      4); // Num Operands
    AltMappings.push_back(&SSMapping);

    const InstructionMapping &SVMapping = getInstructionMapping(2, 1,
      getOperandsMapping({AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 1),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size)}),
      4); // Num Operands
    AltMappings.push_back(&SVMapping);

    const InstructionMapping &VSMapping = getInstructionMapping(2, 1,
      getOperandsMapping({AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 1),
                          AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size)}),
      4); // Num Operands
    AltMappings.push_back(&VSMapping);

    const InstructionMapping &VVMapping = getInstructionMapping(2, 1,
      getOperandsMapping({AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 1),
                          AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size),
                          AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size)}),
      4); // Num Operands
    AltMappings.push_back(&VVMapping);

    return AltMappings;
  }
  default:
    break;
  }
  return RegisterBankInfo::getInstrAlternativeMappings(MI);
}

void AMDGPURegisterBankInfo::applyMappingImpl(
    const OperandsMapper &OpdMapper) const {
  return applyDefaultMapping(OpdMapper);
}

static bool isInstrUniform(const MachineInstr &MI) {
  if (!MI.hasOneMemOperand())
    return false;

  const MachineMemOperand *MMO = *MI.memoperands_begin();
  return AMDGPUInstrInfo::isUniformMMO(MMO);
}

bool AMDGPURegisterBankInfo::isSALUMapping(const MachineInstr &MI) const {
  const MachineFunction &MF = *MI.getParent()->getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();
  for (unsigned i = 0, e = MI.getNumOperands();i != e; ++i) {
    if (!MI.getOperand(i).isReg())
      continue;
    unsigned Reg = MI.getOperand(i).getReg();
    const RegisterBank *Bank = getRegBank(Reg, MRI, *TRI);
    if (Bank && Bank->getID() != AMDGPU::SGPRRegBankID)
      return false;
  }
  return true;
}

const RegisterBankInfo::InstructionMapping &
AMDGPURegisterBankInfo::getDefaultMappingSOP(const MachineInstr &MI) const {
  const MachineFunction &MF = *MI.getParent()->getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();
  SmallVector<const ValueMapping*, 8> OpdsMapping(MI.getNumOperands());

  for (unsigned i = 0, e = MI.getNumOperands(); i != e; ++i) {
    unsigned Size = getSizeInBits(MI.getOperand(i).getReg(), MRI, *TRI);
    OpdsMapping[i] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size);
  }
  return getInstructionMapping(1, 1, getOperandsMapping(OpdsMapping),
                               MI.getNumOperands());
}

const RegisterBankInfo::InstructionMapping &
AMDGPURegisterBankInfo::getDefaultMappingVOP(const MachineInstr &MI) const {
  const MachineFunction &MF = *MI.getParent()->getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();
  SmallVector<const ValueMapping*, 8> OpdsMapping(MI.getNumOperands());
  unsigned OpdIdx = 0;

  unsigned Size0 = getSizeInBits(MI.getOperand(0).getReg(), MRI, *TRI);
  OpdsMapping[OpdIdx++] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size0);

  if (MI.getOperand(OpdIdx).isIntrinsicID())
    OpdsMapping[OpdIdx++] = nullptr;

  unsigned Reg1 = MI.getOperand(OpdIdx).getReg();
  unsigned Size1 = getSizeInBits(Reg1, MRI, *TRI);
  unsigned Bank1 = getRegBankID(Reg1, MRI, *TRI);
  OpdsMapping[OpdIdx++] = AMDGPU::getValueMapping(Bank1, Size1);

  for (unsigned e = MI.getNumOperands(); OpdIdx != e; ++OpdIdx) {
    unsigned Size = getSizeInBits(MI.getOperand(OpdIdx).getReg(), MRI, *TRI);
    OpdsMapping[OpdIdx] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size);
  }

  return getInstructionMapping(1, 1, getOperandsMapping(OpdsMapping),
                               MI.getNumOperands());
}

const RegisterBankInfo::InstructionMapping &
AMDGPURegisterBankInfo::getInstrMappingForLoad(const MachineInstr &MI) const {

  const MachineFunction &MF = *MI.getParent()->getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();
  SmallVector<const ValueMapping*, 8> OpdsMapping(MI.getNumOperands());
  unsigned Size = getSizeInBits(MI.getOperand(0).getReg(), MRI, *TRI);
  unsigned PtrSize = getSizeInBits(MI.getOperand(1).getReg(), MRI, *TRI);

  const ValueMapping *ValMapping;
  const ValueMapping *PtrMapping;

  if (isInstrUniform(MI)) {
    // We have a uniform instruction so we want to use an SMRD load
    ValMapping = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size);
    PtrMapping = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, PtrSize);
  } else {
    ValMapping = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size);
    // FIXME: What would happen if we used SGPRRegBankID here?
    PtrMapping = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, PtrSize);
  }

  OpdsMapping[0] = ValMapping;
  OpdsMapping[1] = PtrMapping;
  const RegisterBankInfo::InstructionMapping &Mapping = getInstructionMapping(
      1, 1, getOperandsMapping(OpdsMapping), MI.getNumOperands());
  return Mapping;

  // FIXME: Do we want to add a mapping for FLAT load, or should we just
  // handle that during instruction selection?
}

unsigned
AMDGPURegisterBankInfo::getRegBankID(unsigned Reg,
                                     const MachineRegisterInfo &MRI,
                                     const TargetRegisterInfo &TRI,
                                     unsigned Default) const {

  const RegisterBank *Bank = getRegBank(Reg, MRI, TRI);
  return Bank ? Bank->getID() : Default;
}

///
/// This function must return a legal mapping, because
/// AMDGPURegisterBankInfo::getInstrAlternativeMappings() is not called
/// in RegBankSelect::Mode::Fast.  Any mapping that would cause a
/// VGPR to SGPR generated is illegal.
///
const RegisterBankInfo::InstructionMapping &
AMDGPURegisterBankInfo::getInstrMapping(const MachineInstr &MI) const {
  const RegisterBankInfo::InstructionMapping &Mapping = getInstrMappingImpl(MI);

  if (Mapping.isValid())
    return Mapping;

  const MachineFunction &MF = *MI.getParent()->getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();
  SmallVector<const ValueMapping*, 8> OpdsMapping(MI.getNumOperands());

  switch (MI.getOpcode()) {
  default:
    return getInvalidInstructionMapping();
  case AMDGPU::G_ADD:
  case AMDGPU::G_SUB:
  case AMDGPU::G_MUL:
  case AMDGPU::G_AND:
  case AMDGPU::G_OR:
  case AMDGPU::G_XOR:
  case AMDGPU::G_SHL:
    if (isSALUMapping(MI))
      return getDefaultMappingSOP(MI);
    LLVM_FALLTHROUGH;

  case AMDGPU::G_FADD:
  case AMDGPU::G_FPTOSI:
  case AMDGPU::G_FPTOUI:
  case AMDGPU::G_FMUL:
  case AMDGPU::G_FMA:
    return getDefaultMappingVOP(MI);
  case AMDGPU::G_IMPLICIT_DEF: {
    unsigned Size = MRI.getType(MI.getOperand(0).getReg()).getSizeInBits();
    OpdsMapping[0] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size);
    break;
  }
  case AMDGPU::G_FCONSTANT:
  case AMDGPU::G_CONSTANT:
  case AMDGPU::G_FRAME_INDEX:
  case AMDGPU::G_BLOCK_ADDR: {
    unsigned Size = MRI.getType(MI.getOperand(0).getReg()).getSizeInBits();
    OpdsMapping[0] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size);
    break;
  }
  case AMDGPU::G_INSERT: {
    unsigned BankID = isSALUMapping(MI) ? AMDGPU::SGPRRegBankID :
                                          AMDGPU::VGPRRegBankID;
    unsigned DstSize = getSizeInBits(MI.getOperand(0).getReg(), MRI, *TRI);
    unsigned SrcSize = getSizeInBits(MI.getOperand(1).getReg(), MRI, *TRI);
    unsigned EltSize = getSizeInBits(MI.getOperand(2).getReg(), MRI, *TRI);
    OpdsMapping[0] = AMDGPU::getValueMapping(BankID, DstSize);
    OpdsMapping[1] = AMDGPU::getValueMapping(BankID, SrcSize);
    OpdsMapping[2] = AMDGPU::getValueMapping(BankID, EltSize);
    OpdsMapping[3] = nullptr;
    break;
  }
  case AMDGPU::G_EXTRACT: {
    unsigned BankID = getRegBankID(MI.getOperand(1).getReg(), MRI, *TRI);
    unsigned DstSize = getSizeInBits(MI.getOperand(0).getReg(), MRI, *TRI);
    unsigned SrcSize = getSizeInBits(MI.getOperand(1).getReg(), MRI, *TRI);
    OpdsMapping[0] = AMDGPU::getValueMapping(BankID, DstSize);
    OpdsMapping[1] = AMDGPU::getValueMapping(BankID, SrcSize);
    OpdsMapping[2] = nullptr;
    break;
  }
  case AMDGPU::G_MERGE_VALUES: {
    unsigned Bank = isSALUMapping(MI) ?
      AMDGPU::SGPRRegBankID : AMDGPU::VGPRRegBankID;
    unsigned DstSize = MRI.getType(MI.getOperand(0).getReg()).getSizeInBits();
    unsigned SrcSize = MRI.getType(MI.getOperand(1).getReg()).getSizeInBits();

    OpdsMapping[0] = AMDGPU::getValueMapping(Bank, DstSize);
    // Op1 and Dst should use the same register bank.
    for (unsigned i = 1, e = MI.getNumOperands(); i != e; ++i)
      OpdsMapping[i] = AMDGPU::getValueMapping(Bank, SrcSize);
    break;
  }
  case AMDGPU::G_BITCAST:
  case AMDGPU::G_INTTOPTR:
  case AMDGPU::G_PTRTOINT:
  case AMDGPU::G_CTLZ:
  case AMDGPU::G_CTLZ_ZERO_UNDEF:
  case AMDGPU::G_CTTZ:
  case AMDGPU::G_CTTZ_ZERO_UNDEF:
  case AMDGPU::G_CTPOP:
  case AMDGPU::G_BSWAP:
  case AMDGPU::G_FABS:
  case AMDGPU::G_FNEG: {
    unsigned Size = MRI.getType(MI.getOperand(0).getReg()).getSizeInBits();
    unsigned BankID = getRegBankID(MI.getOperand(1).getReg(), MRI, *TRI);
    OpdsMapping[0] = OpdsMapping[1] = AMDGPU::getValueMapping(BankID, Size);
    break;
  }
  case AMDGPU::G_TRUNC: {
    unsigned Dst = MI.getOperand(0).getReg();
    unsigned Src = MI.getOperand(1).getReg();
    unsigned Bank = getRegBankID(Src, MRI, *TRI);
    unsigned DstSize = getSizeInBits(Dst, MRI, *TRI);
    unsigned SrcSize = getSizeInBits(Src, MRI, *TRI);
    OpdsMapping[0] = AMDGPU::getValueMapping(Bank, DstSize);
    OpdsMapping[1] = AMDGPU::getValueMapping(Bank, SrcSize);
    break;
  }
  case AMDGPU::G_ZEXT:
  case AMDGPU::G_SEXT:
  case AMDGPU::G_ANYEXT: {
    unsigned Dst = MI.getOperand(0).getReg();
    unsigned Src = MI.getOperand(1).getReg();
    unsigned DstSize = getSizeInBits(Dst, MRI, *TRI);
    unsigned SrcSize = getSizeInBits(Src, MRI, *TRI);
    unsigned SrcBank = getRegBankID(Src, MRI, *TRI,
                                    SrcSize == 1 ? AMDGPU::SGPRRegBankID :
                                    AMDGPU::VGPRRegBankID);
    unsigned DstBank = SrcBank;
    if (SrcSize == 1) {
      if (SrcBank == AMDGPU::SGPRRegBankID)
        DstBank = AMDGPU::VGPRRegBankID;
      else
        DstBank = AMDGPU::SGPRRegBankID;
    }

    OpdsMapping[0] = AMDGPU::getValueMapping(DstBank, DstSize);
    OpdsMapping[1] = AMDGPU::getValueMapping(SrcBank, SrcSize);
    break;
  }
  case AMDGPU::G_FCMP: {
    unsigned Size = MRI.getType(MI.getOperand(2).getReg()).getSizeInBits();
    unsigned Op2Bank = getRegBankID(MI.getOperand(2).getReg(), MRI, *TRI);
    OpdsMapping[0] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 1);
    OpdsMapping[1] = nullptr; // Predicate Operand.
    OpdsMapping[2] = AMDGPU::getValueMapping(Op2Bank, Size);
    OpdsMapping[3] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size);
    break;
  }
  case AMDGPU::G_GEP: {
    for (unsigned i = 0, e = MI.getNumOperands(); i != e; ++i) {
      if (!MI.getOperand(i).isReg())
        continue;

      unsigned Size = MRI.getType(MI.getOperand(i).getReg()).getSizeInBits();
      OpdsMapping[i] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size);
    }
    break;
  }
  case AMDGPU::G_STORE: {
    assert(MI.getOperand(0).isReg());
    unsigned Size = MRI.getType(MI.getOperand(0).getReg()).getSizeInBits();
    // FIXME: We need to specify a different reg bank once scalar stores
    // are supported.
    const ValueMapping *ValMapping =
        AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, Size);
    // FIXME: Depending on the type of store, the pointer could be in
    // the SGPR Reg bank.
    // FIXME: Pointer size should be based on the address space.
    const ValueMapping *PtrMapping =
        AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 64);

    OpdsMapping[0] = ValMapping;
    OpdsMapping[1] = PtrMapping;
    break;
  }

  case AMDGPU::G_ICMP: {
    unsigned Size = MRI.getType(MI.getOperand(2).getReg()).getSizeInBits();
    unsigned Op2Bank = getRegBankID(MI.getOperand(2).getReg(), MRI, *TRI);
    unsigned Op3Bank = getRegBankID(MI.getOperand(3).getReg(), MRI, *TRI);
    unsigned Op0Bank = Op2Bank == AMDGPU::SGPRRegBankID &&
                       Op3Bank == AMDGPU::SGPRRegBankID ?
                       AMDGPU::SCCRegBankID : AMDGPU::VGPRRegBankID;
    OpdsMapping[0] = AMDGPU::getValueMapping(Op0Bank, 1);
    OpdsMapping[1] = nullptr; // Predicate Operand.
    OpdsMapping[2] = AMDGPU::getValueMapping(Op2Bank, Size);
    OpdsMapping[3] = AMDGPU::getValueMapping(Op3Bank, Size);
    break;
  }


  case AMDGPU::G_EXTRACT_VECTOR_ELT: {
    unsigned IdxOp = 2;
    int64_t Imm;
    // XXX - Do we really need to fully handle these? The constant case should
    // be legalized away before RegBankSelect?

    unsigned OutputBankID = isSALUMapping(MI) && isConstant(MI.getOperand(IdxOp), Imm) ?
                            AMDGPU::SGPRRegBankID : AMDGPU::VGPRRegBankID;

    unsigned IdxBank = getRegBankID(MI.getOperand(2).getReg(), MRI, *TRI);
    OpdsMapping[0] = AMDGPU::getValueMapping(OutputBankID, MRI.getType(MI.getOperand(0).getReg()).getSizeInBits());
    OpdsMapping[1] = AMDGPU::getValueMapping(OutputBankID, MRI.getType(MI.getOperand(1).getReg()).getSizeInBits());

    // The index can be either if the source vector is VGPR.
    OpdsMapping[2] = AMDGPU::getValueMapping(IdxBank, MRI.getType(MI.getOperand(2).getReg()).getSizeInBits());
    break;
  }
  case AMDGPU::G_INSERT_VECTOR_ELT: {
    // XXX - Do we really need to fully handle these? The constant case should
    // be legalized away before RegBankSelect?

    int64_t Imm;

    unsigned IdxOp = MI.getOpcode() == AMDGPU::G_EXTRACT_VECTOR_ELT ? 2 : 3;
    unsigned BankID = isSALUMapping(MI) && isConstant(MI.getOperand(IdxOp), Imm) ?
                      AMDGPU::SGPRRegBankID : AMDGPU::VGPRRegBankID;



    // TODO: Can do SGPR indexing, which would obviate the need for the
    // isConstant check.
    for (unsigned i = 0, e = MI.getNumOperands(); i != e; ++i) {
      unsigned Size = getSizeInBits(MI.getOperand(i).getReg(), MRI, *TRI);
      OpdsMapping[i] = AMDGPU::getValueMapping(BankID, Size);
    }


    break;
  }
  case AMDGPU::G_INTRINSIC: {
    switch (MI.getOperand(1).getIntrinsicID()) {
    default:
      return getInvalidInstructionMapping();
    case Intrinsic::maxnum:
    case Intrinsic::minnum:
    case Intrinsic::amdgcn_cvt_pkrtz:
      return getDefaultMappingVOP(MI);
    case Intrinsic::amdgcn_kernarg_segment_ptr: {
      unsigned Size = MRI.getType(MI.getOperand(0).getReg()).getSizeInBits();
      OpdsMapping[0] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, Size);
      break;
    }
    }
    break;
  }
  case AMDGPU::G_INTRINSIC_W_SIDE_EFFECTS: {
    switch (MI.getOperand(0).getIntrinsicID()) {
    default:
      return getInvalidInstructionMapping();
    case Intrinsic::amdgcn_exp_compr:
      OpdsMapping[0] = nullptr; // IntrinsicID
      // FIXME: These are immediate values which can't be read from registers.
      OpdsMapping[1] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 32);
      OpdsMapping[2] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 32);
      // FIXME: Could we support packed types here?
      OpdsMapping[3] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 32);
      OpdsMapping[4] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 32);
      // FIXME: These are immediate values which can't be read from registers.
      OpdsMapping[5] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 32);
      OpdsMapping[6] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 32);
      break;
    case Intrinsic::amdgcn_exp:
      OpdsMapping[0] = nullptr; // IntrinsicID
      // FIXME: These are immediate values which can't be read from registers.
      OpdsMapping[1] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 32);
      OpdsMapping[2] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 32);
      // FIXME: Could we support packed types here?
      OpdsMapping[3] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 32);
      OpdsMapping[4] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 32);
      OpdsMapping[5] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 32);
      OpdsMapping[6] = AMDGPU::getValueMapping(AMDGPU::VGPRRegBankID, 32);
      // FIXME: These are immediate values which can't be read from registers.
      OpdsMapping[7] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 32);
      OpdsMapping[8] = AMDGPU::getValueMapping(AMDGPU::SGPRRegBankID, 32);
      break;
    }
    break;
  }
  case AMDGPU::G_SELECT: {
    unsigned Size = MRI.getType(MI.getOperand(0).getReg()).getSizeInBits();
    unsigned Op1Bank = getRegBankID(MI.getOperand(1).getReg(), MRI, *TRI,
                                    AMDGPU::SGPRRegBankID);
    unsigned Op2Bank = getRegBankID(MI.getOperand(2).getReg(), MRI, *TRI);
    unsigned Op3Bank = getRegBankID(MI.getOperand(3).getReg(), MRI, *TRI);
    bool SGPRSrcs = Op1Bank == AMDGPU::SCCRegBankID &&
                    Op2Bank == AMDGPU::SGPRRegBankID &&
                    Op3Bank == AMDGPU::SGPRRegBankID;
    unsigned Bank = SGPRSrcs ? AMDGPU::SGPRRegBankID : AMDGPU::VGPRRegBankID;
    Op1Bank = SGPRSrcs ? AMDGPU::SCCRegBankID : AMDGPU::SGPRRegBankID;
    OpdsMapping[0] = AMDGPU::getValueMapping(Bank, Size);
    OpdsMapping[1] = AMDGPU::getValueMapping(Op1Bank, 1);
    OpdsMapping[2] = AMDGPU::getValueMapping(Bank, Size);
    OpdsMapping[3] = AMDGPU::getValueMapping(Bank, Size);
    break;
  }

  case AMDGPU::G_LOAD:
    return getInstrMappingForLoad(MI);
  }

  return getInstructionMapping(1, 1, getOperandsMapping(OpdsMapping),
                               MI.getNumOperands());
}
