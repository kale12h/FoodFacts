import re

# Daily recommended values
DAILY_VALUES = {
    'calories':      2000,
    'total_fat':     78,
    'saturated_fat': 20,
    'trans_fat':     0,
    'cholesterol':   300,
    'sodium':        2300,
    'carbohydrates': 275,
    'fiber':         28,
    'sugar':         50,
    'protein':       50,
    'vitamin_d':     20,
    'calcium':       1300,
    'iron':          18,
    'potassium':     4700,
}

# Units for each nutrient
NUTRIENT_UNITS = {
    'calories':      'kcal',
    'total_fat':     'g',
    'saturated_fat': 'g',
    'trans_fat':     'g',
    'cholesterol':   'mg',
    'sodium':        'mg',
    'carbohydrates': 'g',
    'fiber':         'g',
    'sugar':         'g',
    'protein':       'g',
    'vitamin_d':     'mcg',
    'calcium':       'mg',
    'iron':          'mg',
    'potassium':     'mg',
}

# Nutrients that are dangerous if they exceed daily value
HIGH_RISK_NUTRIENTS = [
    'sodium',
    'sugar',
    'saturated_fat',
    'trans_fat',
    'cholesterol',
    'total_fat',
    'calories',
]


def parse_nutrition(text):
    """
    Takes raw text from GPT-4 and extracts nutrition values
    """
    try:
        nutrition_data = {}

        nutrients = list(DAILY_VALUES.keys())

        for nutrient in nutrients:
            pattern = rf'{nutrient}\s*:\s*(\d+\.?\d*|null)'
            match = re.search(pattern, text.lower())
            if match:
                value = match.group(1)
                if value == 'null':
                    nutrition_data[nutrient] = None
                else:
                    nutrition_data[nutrient] = int(float(value))
            else:
                nutrition_data[nutrient] = None

        # Calculate daily value percentages
        percentages = {}
        for nutrient, dv in DAILY_VALUES.items():
            if nutrition_data.get(nutrient) is not None and dv > 0:
                percentages[f'{nutrient}_dv'] = round(
                    (nutrition_data[nutrient] / dv) * 100
                )
            else:
                percentages[f'{nutrient}_dv'] = None

        # Add daily values and units to result
        daily_values_result = {}
        for nutrient, dv in DAILY_VALUES.items():
            daily_values_result[f'{nutrient}_daily'] = dv

        units_result = {}
        for nutrient, unit in NUTRIENT_UNITS.items():
            units_result[f'{nutrient}_unit'] = unit

        result = {
            **nutrition_data,
            **percentages,
            **daily_values_result,
            **units_result
        }

        return {
            "success": True,
            "data": result
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


def get_health_score(nutrition_data):
    """
    Calculates a health score out of 100
    Deducts points for nutrients that exceed daily values
    """
    score = 100
    deductions = []

    for nutrient in HIGH_RISK_NUTRIENTS:
        value = nutrition_data.get(nutrient)
        dv = DAILY_VALUES.get(nutrient)

        if value is None or dv is None or dv == 0:
            continue

        percentage = (value / dv) * 100

        # Deduct points based on how much it exceeds daily value
        if nutrient == 'trans_fat' and value > 0:
            score -= 20
            deductions.append(f"Trans fat present (-20)")

        elif percentage > 100:
            # Exceeds full daily value in one serving
            score -= 25
            deductions.append(f"{nutrient} exceeds 100% daily value (-25)")

        elif percentage > 50:
            # More than half daily value
            score -= 15
            deductions.append(f"{nutrient} exceeds 50% daily value (-15)")

        elif percentage > 30:
            # More than 30% daily value
            score -= 10
            deductions.append(f"{nutrient} exceeds 30% daily value (-10)")

        elif percentage > 20:
            # More than 20% daily value
            score -= 5
            deductions.append(f"{nutrient} exceeds 20% daily value (-5)")

    # Add points for beneficial nutrients
    fiber = nutrition_data.get('fiber')
    if fiber and fiber >= 5:
        score += 10

    protein = nutrition_data.get('protein')
    if protein and protein >= 10:
        score += 10

    # Keep score between 0 and 100
    final_score = max(0, min(100, score))

    return final_score