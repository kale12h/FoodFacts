def identify_category(nutrition_data):
    """
    Identifies product category based on nutrition values
    """
    calories = nutrition_data.get('calories') or 0
    sugar = nutrition_data.get('sugar') or 0
    sodium = nutrition_data.get('sodium') or 0
    protein = nutrition_data.get('protein') or 0
    fiber = nutrition_data.get('fiber') or 0

    if sugar > 20 and calories > 100:
        return 'sugary_drinks'
    elif protein > 5 and calories < 200:
        return 'dairy'
    elif sodium > 300:
        return 'canned_foods'
    elif fiber > 3:
        return 'cereals'
    elif calories < 200 and sugar < 5:
        return 'snacks'
    else:
        return 'sugary_drinks'