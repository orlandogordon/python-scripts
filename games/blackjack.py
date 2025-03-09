import random

class Deck:
    def __init__(self):
        self.cards = []

    def shuffle(self):
        self.cards = []
        for i in range(4): # one iteration for each suit
            for j in range(2,12): # add the ace through the 10 (j) to the deck for the given suit (i)
                self.cards.append(j)
            for i in range(4): # add the four face cards
                self.cards.append(10)
        return random.shuffle(self.cards)

    def size(self):
        return len(self.cards)

    def deal(self):
        return self.cards.pop(random.randint(0,len(self.cards)-1))


class Player:
    def __init__(self, deck, playerID):
        self.cards = []
        self.playerID = playerID
        self.deck = deck
        self.score = 0

    def check_score(self):
        self.score = sum(self.cards)
        while (True):
            if self.score > 21 and 11 in self.cards:
                self.cards[self.cards.index(11)]=1
                self.score = sum(self.cards)
            else:
                break
        return self.score

    def hit(self):
        self.cards.append(self.deck.deal())
        print("Card drawn for " + self.playerID + ": " + str(self.cards[len(self.cards)-1]))



class Blackjack:
    def __init__(self):
        self.deck = Deck()
        self.deck.shuffle()
        self.player = Player(self.deck, "player")
        self.dealer = Player(self.deck, "dealer")

    def startGame(self):
        self.player.hit()
        self.dealer.hit()
        self.player.hit()

        while (self.player.check_score() <= 21):
            print("Player's Score and Cards: " + str(self.player.check_score()) + " - " + str(self.player.cards))
            print("Dealer's Score and Cards: " + str(self.dealer.check_score()) + " - " + str(self.dealer.cards))
            action = input("Would you like to hit or stand: ")
            action = action.lower()
            print("*"*100)
            if action == "stand":
                return 0
            elif action == "hit":
                self.player.hit()
                if self.player.check_score() > 21:
                    print("Player has bust with a score of: " + str(self.player.check_score()))
            else:
                print("Incorrect entry. Try again.")


    def endGame(self):
        while (True):
            if self.dealer.check_score() < 17:
                print("Dealer drawing another card...")
                self.dealer.hit()
            elif self.dealer.check_score() <= 21:
                if self.dealer.check_score() == self.player.check_score():
                    return print("It's a tie! (Push)")
                elif self.dealer.check_score() < self.player.check_score():
                    return print("Dealer has " + str(self.dealer.check_score()) + " and the player has " + str(self.player.check_score()) + ".\nThe player wins!")
                elif self.dealer.check_score() > self.player.check_score():
                    return print("Dealer has " + str(self.dealer.check_score()) + " and the player has " + str(self.player.check_score()) + ".\nThe dealer wins")
                else:
                    return print("Outcome could not be determined")
            elif self.dealer.check_score() > 21:
                return print("Dealer has bust with a score of: " + str(self.dealer.check_score()) + ". The player wins!")
            else:
                return print("Outcome could not be determined")


cont = "yes"
while (cont == "yes"):
    game = Blackjack()
    x = game.startGame()
    if x == 0:
        game.endGame()
    while (True):
        cont = input("Do you want to play again? Please enter yes or no:").lower()
        if cont == "yes" or cont == "no":
            print("\n")
            break
        else:
            print("Invalid response.")
