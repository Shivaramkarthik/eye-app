import json
from datetime import datetime, timezone
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status

from app.models.user import User
from app.models.profile import Profile, ProfileSymptom
from app.models.prescription import Prescription, PrescriptionEyeValue
from app.models.medication import Medication, MedicationSchedule, MedicationLog
from app.models.score import EyeCareScore
from app.models.report import Report
from app.models.sync import SyncRecord
from app.schemas.sync import (
    SyncPushRequest,
    SyncPushResponse,
    SyncOperationResult,
    SyncPullResponse,
)

class SyncService:
    @staticmethod
    async def process_push(db: AsyncSession, user: User, req: SyncPushRequest) -> SyncPushResponse:
        """Processes enqueued offline sync operations idempotently."""
        results: List[SyncOperationResult] = []
        processed_count = 0

        for op in req.operations:
            # Idempotency check: Has this operation_id been processed?
            stmt = select(SyncRecord).where(SyncRecord.operation_id == op.operation_id)
            res = await db.execute(stmt)
            existing = res.scalar_one_or_none()
            if existing:
                results.append(SyncOperationResult(
                    operation_id=op.operation_id,
                    entity_id=op.entity_id,
                    status="PROCESSED",
                    error=None
                ))
                continue

            try:
                # Process entity operation
                if op.entity_type == "profile":
                    await SyncService._sync_profile(db, user, op)
                elif op.entity_type == "prescription":
                    await SyncService._sync_prescription(db, user, op)
                elif op.entity_type == "medication":
                    await SyncService._sync_medication(db, user, op)
                elif op.entity_type == "medication_log":
                    await SyncService._sync_medication_log(db, user, op)
                elif op.entity_type == "report":
                    await SyncService._sync_report(db, user, op)

                # Record sync operation
                sync_record = SyncRecord(
                    id=f"sync_{int(datetime.now().timestamp() * 1000)}_{op.operation_id[:8]}",
                    user_id=user.id,
                    device_id=req.device_id,
                    operation_id=op.operation_id,
                    entity_type=op.entity_type,
                    entity_id=op.entity_id,
                    operation=op.operation,
                    payload=json.dumps(op.payload),
                    version=op.version,
                    status="PROCESSED",
                    created_at=datetime.now(timezone.utc)
                )
                db.add(sync_record)
                await db.commit()

                results.append(SyncOperationResult(
                    operation_id=op.operation_id,
                    entity_id=op.entity_id,
                    status="PROCESSED",
                    error=None
                ))
                processed_count += 1
            except Exception as e:
                await db.rollback()
                results.append(SyncOperationResult(
                    operation_id=op.operation_id,
                    entity_id=op.entity_id,
                    status="REJECTED",
                    error=str(e)
                ))

        return SyncPushResponse(
            device_id=req.device_id,
            processed_count=processed_count,
            results=results
        )

    @staticmethod
    async def _sync_profile(db: AsyncSession, user: User, op):
        p = op.payload
        pid = op.entity_id
        if op.operation == "DELETE":
            stmt = select(Profile).where(Profile.id == pid, Profile.user_id == user.id)
            res = await db.execute(stmt)
            profile = res.scalar_one_or_none()
            if profile:
                profile.deleted_at = datetime.now(timezone.utc)
        else: # CREATE or UPDATE
            stmt = select(Profile).where(Profile.id == pid, Profile.user_id == user.id)
            res = await db.execute(stmt)
            profile = res.scalar_one_or_none()
            if not profile:
                profile = Profile(
                    id=pid,
                    user_id=user.id,
                    name=p.get("name", "User"),
                    dob=p.get("dob", "2000-01-01"),
                    gender=p.get("gender", "Other"),
                    relationship_type=p.get("relationship", "Self"),
                    profile_type=p.get("profileType", "Adult"),
                    prescription_type=p.get("prescriptionType"),
                    blurred_vision_type=p.get("blurredVisionType"),
                    created_at=datetime.now(timezone.utc),
                    updated_at=datetime.now(timezone.utc)
                )
                db.add(profile)
            else:
                profile.name = p.get("name", profile.name)
                profile.dob = p.get("dob", profile.dob)
                profile.gender = p.get("gender", profile.gender)
                profile.relationship_type = p.get("relationship", profile.relationship_type)
                profile.updated_at = datetime.now(timezone.utc)

    @staticmethod
    async def _sync_prescription(db: AsyncSession, user: User, op):
        p = op.payload
        pid = op.entity_id
        if op.operation == "DELETE":
            stmt = select(Prescription).where(Prescription.id == pid, Prescription.user_id == user.id)
            res = await db.execute(stmt)
            presc = res.scalar_one_or_none()
            if presc:
                await db.delete(presc)
        else:
            stmt = select(Prescription).where(Prescription.id == pid, Prescription.user_id == user.id)
            res = await db.execute(stmt)
            presc = res.scalar_one_or_none()
            if not presc:
                presc = Prescription(
                    id=pid,
                    profile_id=p.get("profileId"),
                    user_id=user.id,
                    prescription_date=p.get("prescriptionDate", datetime.now().strftime("%Y-%m-%d")),
                    doctor_name=p.get("doctorName"),
                    clinic_name=p.get("clinicName"),
                    add_power=p.get("addPower"),
                    pd=p.get("pd"),
                    notes=p.get("notes"),
                    image_url=p.get("imageUrl"),
                    source=p.get("source", "MANUAL"),
                    ocr_confidence=p.get("ocrConfidence", 1.0),
                    created_at=datetime.now(timezone.utc),
                    updated_at=datetime.now(timezone.utc)
                )
                db.add(presc)
                await db.flush()

                # Add OD Eye Value
                if "rightSph" in p or "rightCyl" in p:
                    ev_od = PrescriptionEyeValue(
                        id=f"{pid}_OD",
                        prescription_id=pid,
                        eye="OD",
                        sph=p.get("rightSph"),
                        cyl=p.get("rightCyl"),
                        axis=p.get("rightAxis"),
                        sph_status="CONFIRMED" if p.get("rightSph") is not None else "MISSING",
                        cyl_status="CONFIRMED" if p.get("rightCyl") is not None else "MISSING",
                        axis_status="CONFIRMED" if p.get("rightAxis") is not None else "MISSING",
                        created_at=datetime.now(timezone.utc)
                    )
                    db.add(ev_od)

                # Add OS Eye Value
                if "leftSph" in p or "leftCyl" in p:
                    ev_os = PrescriptionEyeValue(
                        id=f"{pid}_OS",
                        prescription_id=pid,
                        eye="OS",
                        sph=p.get("leftSph"),
                        cyl=p.get("leftCyl"),
                        axis=p.get("leftAxis"),
                        sph_status="CONFIRMED" if p.get("leftSph") is not None else "MISSING",
                        cyl_status="CONFIRMED" if p.get("leftCyl") is not None else "MISSING",
                        axis_status="CONFIRMED" if p.get("leftAxis") is not None else "MISSING",
                        created_at=datetime.now(timezone.utc)
                    )
                    db.add(ev_os)

    @staticmethod
    async def _sync_medication(db: AsyncSession, user: User, op):
        p = op.payload
        mid = op.entity_id
        if op.operation == "DELETE":
            stmt = select(Medication).where(Medication.id == mid, Medication.user_id == user.id)
            res = await db.execute(stmt)
            med = res.scalar_one_or_none()
            if med:
                await db.delete(med)
        else:
            stmt = select(Medication).where(Medication.id == mid, Medication.user_id == user.id)
            res = await db.execute(stmt)
            med = res.scalar_one_or_none()
            if not med:
                med = Medication(
                    id=mid,
                    profile_id=p.get("profileId"),
                    user_id=user.id,
                    name=p.get("name", "Eye Drop"),
                    type=p.get("type", "Drop"),
                    dosage=p.get("dosage", "1 Drop"),
                    start_date=p.get("startDate", datetime.now().strftime("%Y-%m-%d")),
                    end_date=p.get("endDate"),
                    active=p.get("active", 1),
                    created_at=datetime.now(timezone.utc),
                    updated_at=datetime.now(timezone.utc)
                )
                db.add(med)

    @staticmethod
    async def _sync_medication_log(db: AsyncSession, user: User, op):
        p = op.payload
        lid = op.entity_id
        if op.operation == "DELETE":
            stmt = select(MedicationLog).where(MedicationLog.id == lid)
            res = await db.execute(stmt)
            log = res.scalar_one_or_none()
            if log:
                await db.delete(log)
        else:
            stmt = select(MedicationLog).where(MedicationLog.id == lid)
            res = await db.execute(stmt)
            log = res.scalar_one_or_none()
            if not log:
                log = MedicationLog(
                    id=lid,
                    medication_id=p.get("medicationId"),
                    schedule_id=p.get("scheduleId", f"{p.get('medicationId')}_sched_0"),
                    scheduled_at=p.get("scheduledAt"),
                    actual_at=p.get("actualAt", p.get("scheduledAt")),
                    status=p.get("status", "TAKEN"),
                    created_at=datetime.now(timezone.utc)
                )
                db.add(log)

    @staticmethod
    async def _sync_report(db: AsyncSession, user: User, op):
        p = op.payload
        rid = op.entity_id
        if op.operation == "DELETE":
            stmt = select(Report).where(Report.id == rid, Report.user_id == user.id)
            res = await db.execute(stmt)
            rpt = res.scalar_one_or_none()
            if rpt:
                await db.delete(rpt)
        else:
            stmt = select(Report).where(Report.id == rid, Report.user_id == user.id)
            res = await db.execute(stmt)
            rpt = res.scalar_one_or_none()
            if not rpt:
                rpt = Report(
                    id=rid,
                    profile_id=p.get("profileId"),
                    user_id=user.id,
                    report_date=p.get("reportDate", datetime.now().strftime("%Y-%m-%d")),
                    title=p.get("title", "Eye Care Report"),
                    clinic_name=p.get("clinicName"),
                    file_path=p.get("filePath"),
                    score_snapshot=p.get("scoreSnapshot", 85),
                    created_at=datetime.now(timezone.utc)
                )
                db.add(rpt)

    @staticmethod
    async def process_pull(db: AsyncSession, user: User) -> SyncPullResponse:
        """Pulls all active user cloud state down to device."""
        # Profiles
        stmt_p = select(Profile).where(Profile.user_id == user.id, Profile.deleted_at.is_(None))
        res_p = await db.execute(stmt_p)
        profiles_db = res_p.scalars().all()
        profiles = [{"id": pr.id, "name": pr.name, "dob": pr.dob, "gender": pr.gender, "relationship": pr.relationship_type, "profileType": pr.profile_type} for pr in profiles_db]

        # Prescriptions
        stmt_pr = select(Prescription).where(Prescription.user_id == user.id)
        res_pr = await db.execute(stmt_pr)
        prescs_db = res_pr.scalars().all()
        prescriptions = [{"id": ps.id, "profileId": ps.profile_id, "prescriptionDate": ps.prescription_date, "doctorName": ps.doctor_name, "clinicName": ps.clinic_name} for ps in prescs_db]

        # Medications
        stmt_m = select(Medication).where(Medication.user_id == user.id)
        res_m = await db.execute(stmt_m)
        meds_db = res_m.scalars().all()
        medications = [{"id": m.id, "profileId": m.profile_id, "name": m.name, "dosage": m.dosage, "type": m.type} for m in meds_db]

        # Reports
        stmt_r = select(Report).where(Report.user_id == user.id)
        res_r = await db.execute(stmt_r)
        rpts_db = res_r.scalars().all()
        reports = [{"id": r.id, "profileId": r.profile_id, "reportDate": r.report_date, "title": r.title} for r in rpts_db]

        return SyncPullResponse(
            server_time=datetime.now(timezone.utc).isoformat(),
            profiles=profiles,
            prescriptions=prescriptions,
            medications=medications,
            reports=reports,
            scores=[]
        )
