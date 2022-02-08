def new_game():
      board = [" "] * 9;
      position = {
            "X": [],
            "O": []
      }
      return board, position

def turn(board, player, position):
      line = "_"
      print(f"{board[0]}\t|\t{board[1]}\t|\t{board[2]}\n"
            f"{line*18}\n"
            f"{board[3]}\t|\t{board[4]}\t|\t{board[5]}\n"
            f"{line*18}\n"
            f"{board[6]}\t|\t{board[7]}\t|\t{board[8]}\n")
      while (True):
            space = input("Player " + player + " - Enter the space you'd like to take (use a single-digit number only): ")
            if space in ["1","2","3","4","5","6","7","8","9"]:
                  space = int(space)
                  if board[space - 1] != " ":
                        print("You entered an invalid number. Please try again")
                  else:
                        board[space-1] = player
                        position[player].append(space)
                        break
            else:
                  print("You entered an invalid number. Please try again")
      return board, position

def check_winner(board, player, position):
      combos = [[1, 2, 3], [4, 5, 6], [7, 8, 9], [1, 4, 7], [2, 5, 8], [3, 6, 9], [1, 5, 9], [3, 5, 7]]
      for combo in combos:
            if all(x in position[player] for x in combo):
                  return True
      return False

def check_draw(position):
      if len(position["X"]) + len(position["O"]) == 9:
            return True
      return False




line = "_"
board = [1, 2, 3, 4, 5, 6, 7, 8, 9]
print(f"{board[0]}\t|\t{board[1]}\t|\t{board[2]}\n"
      f"{line*18}\n"
      f"{board[3]}\t|\t{board[4]}\t|\t{board[5]}\n"
      f"{line*18}\n"
      f"{board[6]}\t|\t{board[7]}\t|\t{board[8]}\n")
print("When prompted, please choose your desired position on the board using the above referenced key ^")


while True:
      board, position = new_game()
      i = 1
      while True:
            print("X's Turn")
            board, position = turn(board, "X", position)
            if i >= 9:
                  if check_draw(position):
                        print(f"{board[0]}\t|\t{board[1]}\t|\t{board[2]}\n"
                              f"{line*18}\n"
                              f"{board[3]}\t|\t{board[4]}\t|\t{board[5]}\n"
                              f"{line*18}\n"
                              f"{board[6]}\t|\t{board[7]}\t|\t{board[8]}\n"
                              f"The result is a draw.")
                        break
            elif i >= 3:
                  if check_winner(board, "X", position):
                        print(f"{board[0]}\t|\t{board[1]}\t|\t{board[2]}\n"
                              f"{line*18}\n"
                              f"{board[3]}\t|\t{board[4]}\t|\t{board[5]}\n"
                              f"{line*18}\n"
                              f"{board[6]}\t|\t{board[7]}\t|\t{board[8]}\n"
                              f"Player X wins!")
                        break

            print("O's Turn")
            board, position = turn(board, "O", position)
            if i >= 9:
                  if check_draw(position):
                        print(f"{board[0]}\t|\t{board[1]}\t|\t{board[2]}\n"
                              f"{line*18}\n"
                              f"{board[3]}\t|\t{board[4]}\t|\t{board[5]}\n"
                              f"{line*18}\n"
                              f"{board[6]}\t|\t{board[7]}\t|\t{board[8]}\n"
                              f"The result is a draw.")
                        break
            elif i >= 3:
                  if check_winner(board, "O", position):
                        print(f"{board[0]}\t|\t{board[1]}\t|\t{board[2]}\n"
                              f"{line*18}\n"
                              f"{board[3]}\t|\t{board[4]}\t|\t{board[5]}\n"
                              f"{line*18}\n"
                              f"{board[6]}\t|\t{board[7]}\t|\t{board[8]}\n"
                              f"Player O wins!")
                        break
            i += 1
      cont = input("Would you like to play again? (enter yes or no)")
      cont = cont.lower()
      if cont != "yes":
            break


