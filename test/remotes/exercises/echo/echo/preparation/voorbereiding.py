from random import choice

invoer = open('words.txt', 'r')
woorden = []
for woord in invoer:
    woord = woord.strip()
    if len(woord) > 6 and woord.islower():
        woorden.append(woord)
    
invoer = open('invoer.txt', 'w')    
for _ in range(50):
    woord = choice(woorden)
    invoer.write('%s\n' % woord)
