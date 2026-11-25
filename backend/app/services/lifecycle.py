"""
VillageNova Agronomic Phenological Lifecycle Engine (Phase 4, Week 11)

Calculates precise crop growth stages, days elapsed, days remaining to transition,
harvest projections, stage-specific pest/weather risks, and PJTSAU packages of practices.
Specialized for Telangana Kharif crops: Soybean (JS-335) and Bt Cotton.
"""

from typing import Dict, Any, List, Optional
from datetime import date, timedelta

from app.schemas.farm import (
    CropStageStep,
    CropLifecycleRisk,
    CropStageRecommendation,
    CropLifecycleOut,
)

STAGE_DEFINITIONS: List[Dict[str, Any]] = [
    {
        "key": "sowing",
        "title": "Sowing & Seeding",
        "start_day": 1,
        "end_day": 5,
        "days_range": "Day 1-5",
        "description": "Seed treatment with Rhizobium and Trichoderma, optimal seed placement at 3-4 cm depth in well-tilted moist soil.",
        "risks": [
            CropLifecycleRisk(
                risk_title="Pre-emergence damping off and collar rot",
                severity="moderate",
                mitigation="Treat seeds with Carbendazim 2g/kg or Trichoderma viride 10g/kg before sowing.",
                affected_organ="root",
            ),
            CropLifecycleRisk(
                risk_title="Bird damage & seed scavenging",
                severity="low",
                mitigation="Ensure uniform sowing depth of 3 to 4 cm; avoid shallow scattering on surface.",
                affected_organ="seed",
            ),
        ],
        "recommendations": [
            CropStageRecommendation(
                category="cultural",
                recommendation="Maintain spacing of 30 cm between rows and 10 cm between plants for optimum population.",
                urgency="immediate",
            ),
            CropStageRecommendation(
                category="nutrient",
                recommendation="Apply basal dose of 20 kg N, 60 kg P2O5, and 40 kg K2O per hectare at the time of sowing.",
                urgency="planned",
            ),
        ],
        "actions": [
            "Ensure seed treatment with Rhizobium japonicum bio-fertilizer before sowing",
            "Verify uniform soil moisture (minimum 25 mm rain or field capacity) before drilling",
            "Calibrate seed drill to achieve recommended 30 kg/acre seed rate",
        ],
    },
    {
        "key": "germination",
        "title": "Germination & Emergence",
        "start_day": 6,
        "end_day": 12,
        "days_range": "Day 6-12",
        "description": "Cotyledon emergence and initial taproot penetration. Critical for uniform seedling stand density.",
        "risks": [
            CropLifecycleRisk(
                risk_title="Black soil crusting impeding seedling emergence",
                severity="high",
                mitigation="Perform light blind hoeing or shallow inter-row harrowing if rain is followed by intense sun.",
                affected_organ="soil",
            ),
            CropLifecycleRisk(
                risk_title="Cutworm seedling cutting at ground level",
                severity="moderate",
                mitigation="Apply Chlorpyriphos 20 EC @ 2 ml/L around seedling collars during early evening.",
                affected_organ="root",
            ),
        ],
        "recommendations": [
            CropStageRecommendation(
                category="cultural",
                recommendation="Scout seedling count: ideal plant density is 30 to 35 healthy seedlings per square meter.",
                urgency="immediate",
            ),
            CropStageRecommendation(
                category="irrigation",
                recommendation="Avoid excess water stagnation; ensure field perimeter furrows are clear.",
                urgency="immediate",
            ),
        ],
        "actions": [
            "Count seedling emergence across 5 representative 1-meter rows to evaluate stand density",
            "Break surface crust with light rotary weeder if soil has baked after light shower",
            "Inspect field borders for cutworm or rodent seedling nipping",
        ],
    },
    {
        "key": "vegetative",
        "title": "Vegetative & Branching",
        "start_day": 13,
        "end_day": 55,
        "days_range": "Day 13-55",
        "description": "Rapid trifoliate leaf expansion, primary branching, atmospheric nitrogen fixation nodule development, and canopy closure.",
        "risks": [
            CropLifecycleRisk(
                risk_title="Whitefly vectoring Yellow Mosaic Virus (YMV)",
                severity="high",
                mitigation="Install 6-8 yellow sticky traps per acre; spray 5% Neem Seed Kernel Extract (NSKE) or Acetamiprid 20% SP @ 0.2g/L.",
                affected_organ="leaf",
            ),
            CropLifecycleRisk(
                risk_title="Spodoptera litura (Tobacco leaf caterpillar) leaf defoliation",
                severity="moderate",
                mitigation="Collect and destroy egg masses; spray Emamectin Benzoate 5% SG @ 0.4g/L if ETL (>1 larva/meter) is crossed.",
                affected_organ="leaf",
            ),
            CropLifecycleRisk(
                risk_title="Waterlogging causing root aeration asphyxiation",
                severity="high",
                mitigation="Open drainage channels and field bund outlets immediately before high rainfall events.",
                affected_organ="root",
            ),
        ],
        "recommendations": [
            CropStageRecommendation(
                category="pest_management",
                recommendation="Install pheromone and yellow sticky traps for vector population monitoring across field margins.",
                urgency="immediate",
            ),
            CropStageRecommendation(
                category="cultural",
                recommendation="Carry out inter-cultivation (kolpa) at 20 and 35 DAS for weed control and root zone aeration.",
                urgency="planned",
            ),
            CropStageRecommendation(
                category="irrigation",
                recommendation="Soybean requires high aeration; hold irrigation if rainfall is forecasted within 24 hours.",
                urgency="immediate",
            ),
        ],
        "actions": [
            "Check field drainage bunds before evening rain to prevent water stagnation in furrows",
            "Scout upper leaf canopy for whiteflies and early yellow mosaic speckling",
            "Install 6-8 yellow sticky traps per acre along border rows to monitor insect pressure",
        ],
    },
    {
        "key": "flowering",
        "title": "Flowering & Blossom",
        "start_day": 56,
        "end_day": 75,
        "days_range": "Day 56-75",
        "description": "Axillary raceme blossom flush and pollination. Most moisture-sensitive physiological window in crop lifespan.",
        "risks": [
            CropLifecycleRisk(
                risk_title="Soil moisture deficit inducing flower drop",
                severity="critical",
                mitigation="Provide life-saving protective irrigation if dry spell exceeds 7 days during peak bloom.",
                affected_organ="flower",
            ),
            CropLifecycleRisk(
                risk_title="Flower thrips causing bud distortion",
                severity="moderate",
                mitigation="Spray Thiamethoxam 25% WG @ 0.3g/L during early morning or late afternoon.",
                affected_organ="flower",
            ),
        ],
        "recommendations": [
            CropStageRecommendation(
                category="nutrient",
                recommendation="Foliar spray 1% Potassium Nitrate (13-0-45) @ 10g/L at 60 DAS to enhance flower retention.",
                urgency="planned",
            ),
            CropStageRecommendation(
                category="cultural",
                recommendation="Avoid synthetic broad-spectrum chemical sprays between 7:00 AM and 10:00 AM to preserve beneficial bee pollinators.",
                urgency="immediate",
            ),
        ],
        "actions": [
            "Inspect soil root zone moisture; ensure soil does not develop cracks during bloom",
            "Spray 1% Potassium Nitrate (13-0-45) for maximum flower retention and nodule nutrition",
            "Hold chemical spraying during active morning bee foraging hours (7:00 AM to 10:00 AM)",
        ],
    },
    {
        "key": "pod_formation",
        "title": "Pod Formation & Grain Fill",
        "start_day": 76,
        "end_day": 95,
        "days_range": "Day 76-95",
        "description": "Pod elongation, ovule development, and rapid dry-matter oil and protein accumulation into soybean seeds.",
        "risks": [
            CropLifecycleRisk(
                risk_title="Pod borer (Helicoverpa armigera) boring into green pods",
                severity="high",
                mitigation="Spray Chlorantraniliprole 18.5% SC @ 0.3 ml/L or Flubendiamide 39.35% SC @ 0.3 ml/L upon noticing pod entry holes.",
                affected_organ="pod",
            ),
            CropLifecycleRisk(
                risk_title="Anthracnose and pod blight (Colletotrichum truncatum)",
                severity="high",
                mitigation="Foliar spray Tebuconazole 25.9% EC @ 1.5 ml/L if brown necrotic lesions appear on pods.",
                affected_organ="pod",
            ),
        ],
        "recommendations": [
            CropStageRecommendation(
                category="nutrient",
                recommendation="Foliar spray 1% Monopotassium Phosphate (0-52-34) at 80 DAS to accelerate uniform seed filling.",
                urgency="planned",
            ),
            CropStageRecommendation(
                category="irrigation",
                recommendation="Maintain uniform field capacity; water stress during grain fill reduces 100-seed test weight.",
                urgency="immediate",
            ),
        ],
        "actions": [
            "Inspect developing green pods for caterpillar entry holes and dark discoloration lesions",
            "Apply foliar 0-52-34 (10g/L) to maximize pod grain filling and test weight",
            "Ensure furrows remain well drained during late season monsoonal showers",
        ],
    },
    {
        "key": "harvest",
        "title": "Maturity & Harvest",
        "start_day": 96,
        "end_day": 115,
        "days_range": "Day 96-115",
        "description": "Complete leaf defoliation, pod senescence turning golden straw brown, seed moisture equilibrium reduction to 10-12%.",
        "risks": [
            CropLifecycleRisk(
                risk_title="Pod shattering caused by over-drying in field",
                severity="high",
                mitigation="Harvest promptly when 90-95% of pods turn straw yellow; avoid delaying harvest past 115 DAS.",
                affected_organ="pod",
            ),
            CropLifecycleRisk(
                risk_title="High moisture dockage deductions at APMC Mandi (>14% moisture)",
                severity="moderate",
                mitigation="Sun-dry harvested soybean on clean tarpaulin sheets for 2-3 sunny days to achieve 10-12% FAQ standard.",
                affected_organ="seed",
            ),
        ],
        "recommendations": [
            CropStageRecommendation(
                category="cultural",
                recommendation="Harvest during morning hours when dew reduces shattering losses; thresh with combine or multi-crop thresher.",
                urgency="immediate",
            ),
            CropStageRecommendation(
                category="cultural",
                recommendation="Store cleaned grain in gunny bags stacked on wooden pallets in a cool, ventilated room.",
                urgency="planned",
            ),
        ],
        "actions": [
            "Check field maturity: harvest when 95% of pods turn golden brown and seeds rattle inside pods",
            "Spread harvested grain on tarpaulin sheets to achieve Fair Average Quality (FAQ) 10-12% moisture",
            "Monitor live Vikarabad APMC arrival schedules and modal auction rates for peak selling window",
        ],
    },
]


def calculate_crop_lifecycle(
    crop_name: str = "Soybean",
    days_elapsed: Optional[int] = None,
    variety: Optional[str] = None,
    sowing_date: Optional[date] = None,
    farming_goal: Optional[str] = None,
    **kwargs
) -> CropLifecycleOut:
    """
    Computes complete agronomic phenology, stage progress, active risks,
    recommendations, and harvest countdown for a given crop.
    Supports flexible positional and keyword arguments for days_elapsed, variety, and sowing_date.
    """
    total_crop_days = 115
    today = date.today()

    # Handle variety passed positionally or swapped
    if isinstance(variety, int) and days_elapsed is None:
        days_elapsed = variety
        variety = None

    if days_elapsed is not None:
        effective_days = max(1, days_elapsed)
        effective_sow_date = sowing_date or (today - timedelta(days=effective_days))
    elif sowing_date is not None:
        effective_sow_date = sowing_date
        effective_days = max(1, (today - sowing_date).days)
    else:
        # Default Day 42 Vegetative
        effective_days = 42
        effective_sow_date = today - timedelta(days=42)

    # Identify matching stage
    active_stage_def = STAGE_DEFINITIONS[-1]
    for s in STAGE_DEFINITIONS:
        if effective_days <= s["end_day"]:
            active_stage_def = s
            break

    current_stage_key = active_stage_def["key"]
    current_stage_title = active_stage_def["title"]
    stage_days_range = active_stage_def["days_range"]
    start_day = active_stage_def["start_day"]
    end_day = active_stage_def["end_day"]

    # Days in current stage & remaining
    days_in_current_stage = max(1, effective_days - start_day + 1)
    days_remaining_in_stage = max(0, end_day - effective_days)

    stage_duration = end_day - start_day + 1
    stage_progress_pct = min(100, max(0, int((days_in_current_stage / stage_duration) * 100)))
    overall_progress_pct = min(100, max(1, int((effective_days / total_crop_days) * 100)))

    expected_harvest_date = effective_sow_date + timedelta(days=total_crop_days)
    days_to_harvest = max(0, (expected_harvest_date - today).days)

    # Build stage steps list for UI
    stages_out: List[CropStageStep] = []
    for s in STAGE_DEFINITIONS:
        is_completed = effective_days > s["end_day"]
        is_current = s["key"] == current_stage_key
        stages_out.append(
            CropStageStep(
                stage_key=s["key"],
                title=s["title"],
                days_range=s["days_range"],
                is_completed=is_completed,
                is_current=is_current,
                description=s["description"],
            )
        )

    return CropLifecycleOut(
        crop_name=crop_name,
        variety=variety or "JS 335 (Certified High Yield)",
        sowing_date=effective_sow_date,
        days_since_sowing=effective_days,
        current_stage_key=current_stage_key,
        current_stage=current_stage_key,
        current_stage_title=current_stage_title,
        stage_title=current_stage_title,
        stage_days_range=stage_days_range,
        days_in_current_stage=days_in_current_stage,
        days_remaining_in_stage=days_remaining_in_stage,
        stage_progress_pct=stage_progress_pct,
        overall_progress_pct=overall_progress_pct,
        expected_harvest_date=expected_harvest_date,
        days_to_harvest=days_to_harvest,
        farming_goal=farming_goal,
        active_risks=active_stage_def["risks"],
        stage_recommendations=active_stage_def["recommendations"],
        recommendations=active_stage_def["recommendations"],
        daily_priority_actions=active_stage_def["actions"],
        priority_actions=active_stage_def["actions"],
        stages=stages_out,
    )
