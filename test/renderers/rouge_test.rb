require 'test_helper'

class RougeTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  test 'markdown output should be equal' do
    input = "
    >>> hex2letter = leet2letter('leet.txt')
    >>> hex2letter
    {'0': {'O'}, '1': {'I'}, '2': {'Z', 'R'}, '3': {'E'}, '5': {'S'}, '6': {'G'}, '7': {'L', 'Y', 'T'}, '9': {'P'}}

    >>> letter2hex = letter2leet(hex2letter)
    >>> letter2hex
    {'O': '0', 'I': '1', 'Z': '2', 'R': '2', 'E': '3', 'S': '5', 'G': '6', 'L': '7', 'Y': '7', 'T': '7', 'P': '9'}

    >>> leetspeak('BADASS', letter2hex)
    'BADA55'
    >>> leetspeak('fbi', letter2hex)
    'FB1'
    >>> leetspeak('SHRUBBERY', letter2hex)
    '5H2UBB327'
    >>> leetspeak('REBECCA', letter2hex)
    '23B3CCA'

    >>> isHexKleur('#BADA55')
    True
    >>> isHexKleur('#fb1')
    True
    >>> isHexKleur('#5H2UBB327')
    False
    >>> isHexKleur('#663399')
    True

    >>> kleur('BADASS', letter2hex)
    '#BADA55'
    >>> kleur('fbi', letter2hex)
    '#FB1'
    >>> kleur('SHRUBBERY', letter2hex)
    Traceback (most recent call last):
    AssertionError: ongeldige kleur
    >>> kleur('REBECCA', letter2hex)
    Traceback (most recent call last):
    AssertionError: ongeldige kleur
    "
    expected = "
<pre><code>&gt;&gt;&gt; hex2letter = leet2letter('leet.txt')
&gt;&gt;&gt; hex2letter
{'0': {'O'}, '1': {'I'}, '2': {'Z', 'R'}, '3': {'E'}, '5': {'S'}, '6': {'G'}, '7': {'L', 'Y', 'T'}, '9': {'P'}}

&gt;&gt;&gt; letter2hex = letter2leet(hex2letter)
&gt;&gt;&gt; letter2hex
{'O': '0', 'I': '1', 'Z': '2', 'R': '2', 'E': '3', 'S': '5', 'G': '6', 'L': '7', 'Y': '7', 'T': '7', 'P': '9'}

&gt;&gt;&gt; leetspeak('BADASS', letter2hex)
'BADA55'
&gt;&gt;&gt; leetspeak('fbi', letter2hex)
'FB1'
&gt;&gt;&gt; leetspeak('SHRUBBERY', letter2hex)
'5H2UBB327'
&gt;&gt;&gt; leetspeak('REBECCA', letter2hex)
'23B3CCA'

&gt;&gt;&gt; isHexKleur('#BADA55')
True
&gt;&gt;&gt; isHexKleur('#fb1')
True
&gt;&gt;&gt; isHexKleur('#5H2UBB327')
False
&gt;&gt;&gt; isHexKleur('#663399')
True

&gt;&gt;&gt; kleur('BADASS', letter2hex)
'#BADA55'
&gt;&gt;&gt; kleur('fbi', letter2hex)
'#FB1'
&gt;&gt;&gt; kleur('SHRUBBERY', letter2hex)
Traceback (most recent call last):
AssertionError: ongeldige kleur
&gt;&gt;&gt; kleur('REBECCA', letter2hex)
Traceback (most recent call last):
AssertionError: ongeldige kleur
</code></pre>

"
    assert_equal expected, markdown(input), 'markdown output is incorrect'
  end
end
