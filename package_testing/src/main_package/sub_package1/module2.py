def function_multiply(x, y):
    """Multiplies two numbers."""
    return x * y
def function_divide(x, y):
    """Divides x by y."""
    if y == 0:
        raise ValueError("Cannot divide by zero")
    return x / y
