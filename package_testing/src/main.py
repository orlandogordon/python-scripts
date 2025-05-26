# from main_package import Utilities
import main_package
def main():
    # sys.path.append(str(Path(__file__).parent))
    # root_dir=Path(__file__).parent.parent

    x = main_package.Utilities()
    print(x.add(5, 3))          # Should print 8
    print(x.subtract(10, 4))    # Should print 6
    print(x.multiply(2, 3))      # Should print 6
    print(x.divide(8, 2))        # Should print 4.0 
    print(x.function3())         # Should print "This is function3 from module3 in sub_package2"
    print(x.function4())         # Should print "This is function4 from module4 in sub_package2"
    
if __name__ == "__main__":
    main()