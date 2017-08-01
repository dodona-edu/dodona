from random import randint

invoer = open('invoer.txt', 'w')
uitvoer = open('uitvoer.txt', 'w')

def controlecijfer(cijfers):
    som = 0
    for i, c in enumerate(cijfers):
        som += (i + 1) * int(c)
    return som % 11

for _ in range(50):
    isbn = [str(randint(0, 9)) for x in range(9)]
    invoer.write('%s\n' % '\n'.join(isbn))
    uitvoer.write('%d\n' % controlecijfer(isbn))