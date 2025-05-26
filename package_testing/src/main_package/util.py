from . import sub_package1
from . import sub_package2

class Utilities:
    def __init__(self):
        print("Utilities class initialized")
    def add(self, x, y):
        return sub_package1.module1.function_add(x, y)
    def subtract(self, x, y):
        return sub_package1.module1.function_subtract(x, y)
    def multiply(self, x, y):
        return sub_package1.module2.function_multiply(x, y)
    def divide(self, x, y):
        return sub_package1.module2.function_divide(x, y)
    def function3(self):
        return sub_package2.module3.function3()
    def function4(self):
        return sub_package2.module4.function4()