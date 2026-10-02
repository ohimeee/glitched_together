D = r"C:\Users\User\OneDrive\Desktop\Coding\glitched_together\tools\core_sky"
exec(open(D + r"\setup.py").read())
exec(open(D + r"\islands.py").read())
add_haze(bpy.data.materials["C_Sheet"], HAZE, start=1200, end=16000, strength=0.9)
exec(open(D + r"\props.py").read())
print("core sky built")
