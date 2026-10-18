"""Stable, dark, desaturated cloth that remains subdued under the mobile torch."""
import unreal as u
def apply():
    material=u.load_asset('/Game/Imported/M_MourningFabric')
    assert material
    u.MaterialEditingLibrary.delete_all_material_expressions(material)
    tex=u.MaterialEditingLibrary.create_material_expression(material,u.MaterialExpressionTextureSample)
    tex.set_editor_property('texture',u.load_asset('/Game/Imported/M_MourningFabric_texture'))
    tint=u.MaterialEditingLibrary.create_material_expression(material,u.MaterialExpressionConstant3Vector)
    tint.set_editor_property('constant',u.LinearColor(.004,.005,.006))
    mul=u.MaterialEditingLibrary.create_material_expression(material,u.MaterialExpressionMultiply)
    assert u.MaterialEditingLibrary.connect_material_expressions(tex,'R',mul,'A')
    assert u.MaterialEditingLibrary.connect_material_expressions(tint,'',mul,'B')
    assert u.MaterialEditingLibrary.connect_material_property(mul,'',u.MaterialProperty.MP_BASE_COLOR)
    rough=u.MaterialEditingLibrary.create_material_expression(material,u.MaterialExpressionConstant);rough.set_editor_property('r',.98)
    u.MaterialEditingLibrary.connect_material_property(rough,'',u.MaterialProperty.MP_ROUGHNESS)
    material.set_editor_property('two_sided',True);material.set_editor_property('used_with_skeletal_mesh',True)
    u.MaterialEditingLibrary.recompile_material(material);u.EditorAssetLibrary.save_loaded_asset(material)
