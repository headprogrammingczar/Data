{-# LANGUAGE UndecidableInstances, StandaloneDeriving, NoMonomorphismRestriction, PostfixOperators #-}
module IRC.Data.L where

import Data.ByteString.Lazy.Char8 (pack)
import Data.Digest.Pure.SHA (showDigest, sha1)
import Control.Applicative
import Control.Monad
import Control.Arrow
import Data.Monoid
import Data.List
import Data.Char
import Data.Number.CReal
import Data.Number.Natural
import Data.Number.Dif
import Text.Printf
import Text.PrettyPrint.HughesPJ (text)
import Data.Ratio
import Numeric

data Complexity = P | NP deriving (Show, Read, Enum, Bounded, Eq, Ord)

showBinary n = showIntAtBase 2 (head . show) n ""

bits = logBase 2

replace :: (Eq a, Functor f) => a -> a -> f a -> f a
replace r w = fmap (\c -> if c == r then w else c)

hash :: String -> String
hash = showDigest . sha1 . pack

primes 1 = []
primes n = let f = primes' n 2 in f : primes (n `div` f)
  where
    primes' n t = if n `mod` t == 0 then t else primes' n (t+1)

(??) t f p = if p then t else f

(.:) :: (Functor f, Functor f1) => (a -> b) -> f (f1 a) -> f (f1 b)
(.:) = fmap . fmap

(.::) :: (Functor f) => (a1 -> b) -> (a -> a1) -> f a -> f b
(.::) = fmap .: fmap

(...) [x] = repeat x
(...) x@(x0:xs) = scanl (+) x0 ((zipWith (-) xs x)...)

flip' :: (Functor f) => f (a -> b) -> a -> f b
flip' fs x = fmap ($ x) fs

(<=>) = compare

perms = filterM (const [True, False]) . nub . sort

combs size = filter ((size ==) . length) . perms

morse = unwords . map morseChar . map toLower

morseChar :: Char -> String
morseChar 'a' = ".-"
morseChar 'b' = "-..."
morseChar 'c' = "-.-."
morseChar 'd' = "-.."
morseChar 'e' = "."
morseChar 'f' = "..-."
morseChar 'g' = "--."
morseChar 'h' = "...."
morseChar 'i' = ".."
morseChar 'j' = ".---"
morseChar 'k' = "-.-"
morseChar 'l' = ".-.."
morseChar 'm' = "--"
morseChar 'n' = "-."
morseChar 'o' = "---"
morseChar 'p' = ".--."
morseChar 'q' = "--.-"
morseChar 'r' = ".-."
morseChar 's' = "..."
morseChar 't' = "-"
morseChar 'u' = "..-"
morseChar 'v' = "...-"
morseChar 'w' = ".--"
morseChar 'x' = "-..-"
morseChar 'y' = "-.--"
morseChar 'z' = "--.."
morseChar '1' = ".----"
morseChar '2' = "..---"
morseChar '3' = "...--"
morseChar '4' = "....-"
morseChar '5' = "....."
morseChar '6' = "-...."
morseChar '7' = "--..."
morseChar '8' = "---.."
morseChar '9' = "----."
morseChar '0' = "-----"
morseChar ' ' = "     "
morseChar _ = "!"

-- to annoy mz and neutrak
π :: (Floating a) => a
π = pi

integerToBreakfast = (["Cornflakes", "Pornflakes", "Strawberry jam toast", "Grapefruit", "Cup of tea and a biscuit, gotta dash",
                       "Bacon, eggs, toast, tomato and mushroom. You deserve it", "Waffles", "Porridge of some description",
                       "Orange juice and muffins", "Apples, pears, mango and kiwi", "A selection of cold meats with crisp bread",
                       "Headache pills and water", "Leftover pizza", "Leftover vindaloo curry"] !!)

botsnack = text ":D"

-- just to annoy the zorkers
zork = text "You are in an open field looking north"

go x = text "You have been eaten by a grue"

light x = text "Actually, it is quite heavy"

lamp = undefined

north = undefined
south = undefined
east = undefined
west = undefined

want = False

cake = ["One 18.25 ounce package chocolate cake mix.",
        "One can prepared coconut pecan frosting.",
        "Three slash four cup vegetable oil.",
        "Four large eggs.",
        "One cup semi-sweet chocolate chips.",
        "Three slash four cups butter or margarine.",
        "One and two third cups granulated sugar.",
        "Two cups all-purpose flour.",
        "Don't forget garnishes such as:",
        "Fish shaped crackers.",
        "Fish shaped candies.",
        "Fish shaped solid waste.",
        "Fish shaped dirt.",
        "Fish shaped ethylbenzene.",
        "Pull and peel licorice.",
        "Fish shaped organic compounds and sediment shaped sediment.",
        "Candy coated peanut butter pieces. Shaped like fish.",
        "One cup lemon juice.",
        "Alpha resins.",
        "Unsaturated polyester resin.",
        "Fiberglass surface resins.",
        "And volatile malted milk impoundments.",
        "Nine large egg yolks.",
        "Twelve medium geosynthetic membranes.",
        "One cup granulated sugar.",
        "An entry called 'how to kill someone with your bare hands.'",
        "Two cups rhubarb, sliced.",
        "Two slash three cups granulated rhubarb.",
        "One tablespoon all-purpose rhubarb.",
        "One teaspoon grated orange rhubarb.",
        "Three tablespoons rhubarb, on fire.",
        "One large rhubarb.",
        "One cross borehole electro-magnetic imaging rhubarb.",
        "Two tablespoons rhubarb juice.",
        "Adjustable aluminum head positioner.",
        "Slaughter electric needle injector.",
        "Cordless electric needle injector.",
        "Injector needle driver.",
        "Injector needle gun.",
        "Cranial caps.",
        "And it contains proven preservatives, deep penetration agents, and gas and odor control chemicals.",
        "That will deodorize and preserve putrid tissue."]

facts = [
        "The billionth digit of Pi is 9.",
        "Humans can survive underwater. But not for very long.",
        "A nanosecond lasts one billionth of a second.",
        "Honey does not spoil.",
        "The atomic weight of Germanium is seven two point six four.",
        "An ostrich's eye is bigger than its brain.",
        "Rats cannot throw up.",
        "Iguanas can stay underwater for twenty-eight point seven minutes.",
        "The moon orbits the Earth every 27.32 days.",
        "A gallon of water weighs 8.34 pounds.",
        "According to Norse legend, thunder god Thor's chariot was pulled across the sky by two goats.",
        "Tungsten has the highest melting point of any metal, at 3,410 degrees Celsius.",
        "Gently cleaning the tongue twice a day is the most effective way to fight bad breath.",
        "The Tariff Act of 1789, established to protect domestic manufacture, was the second statute ever enacted by the United States government.",
        "The value of Pi is the ratio of any circle's circumference to its diameter in Euclidean space.",
        "The Mexican-American War ended in 1848 with the signing of the Treaty of Guadalupe Hidalgo.",
        "In 1879, Sandford Fleming first proposed the adoption of worldwide standardized time zones at the Royal Canadian Institute.",
        "Marie Curie invented the theory of radioactivity, the treatment of radioactivity, and dying of radioactivity.",
        "At the end of The Seagull by Anton Chekhov, Konstantin kills himself.",
        "If you have trouble with simple counting, use the following mnemonic device: one comes before two comes before 60 comes after 12 comes before six trillion comes after 504. This will make your earlier counting difficulties seem like no big deal.",
        "Hot water freezes quicker than cold water.",
        "Volcano-ologists are experts in the study of volcanoes.",
        "Cellular phones will not give you cancer. Only hepatitis.",
        "In Greek myth, Prometheus stole fire from the Gods and gave it to humankind. The jewelry he kept for himself.",
        "The Schrodinger's cat paradox outlines a situation in which a cat in a box must be considered, for all intents and purposes, simultaneously alive and dead. Schrodinger created this paradox as a justification for killing cats.",
        "In 1862, Abraham Lincoln signed the Emancipation Proclamation, freeing the slaves. Like everything he did, Lincoln freed the slaves while sleepwalking, and later had no memory of the event.",
        "The plural of surgeon general is surgeons general. The past tense of surgeons general is surgeonsed general",
        "Contrary to popular belief, the Eskimo does not have one hundred different words for snow. They do, however, have two hundred and thirty-four words for fudge.",
        "Halley's Comet can be viewed orbiting Earth every seventy-six years. For the other seventy-five, it retreats to the heart of the sun, where it hibernates undisturbed.",
        "The first commercial airline flight took to the air in 1914. Everyone involved screamed the entire way.",
        "The Sun is 330,330 times larger than Earth.",
        "Dental floss has superb tensile strength.",
        "Raseph, the Semitic god of war and plague, had a gazelle growing out of his forehead.",
        "Human tapeworms can grow up to twenty-two point nine meters.",
        "The square root of rope is string.",
        "89% of magic tricks are not magic. Technically, they are sorcery.",
        "At some point in their lives 1 in 6 children will be abducted by the Dutch.",
        "According to most advanced algorithms, the world's best name is Craig.",
        "To make a photocopier, simply photocopy a mirror.",
        "Dreams are the subconscious mind's way of reminding people to go to school naked and have their teeth fall out.",
        "Whales are twice as intelligent, and three times as delicious, as humans.",
        "Pants were invented by sailors in the sixteenth century to avoid Poseidon's wrath. It was believed that the sight of naked sailors angered the sea god.",
        "In Greek myth, the craftsman Daedalus invented human flight so a group of Minotaurs would stop teasing him about it.",
        "The average life expectancy of a rhinoceros in captivity is 15 years.",
        "China produces the world's second largest crop of soybeans.",
        "In Victorian England, a commoner was not allowed to look directly at the Queen, due to a belief at the time that the poor had the ability to steal thoughts. Science now believes that less than 4% of poor people are able to do this.",
        "In 1948, at the request of a dying boy, baseball legend Babe Ruth ate seventy-five hot dogs, then died of hot dog poisoning.",
        "William Shakespeare did not exist. His plays were masterminded in 1589 by Francis Bacon, who used a Ouija board to enslave play-writing ghosts.",
        "It is incorrectly noted that Thomas Edison invented 'push-ups' in 1878. Nikolai Tesla had in fact patented the activity three years earlier, under the name 'Tesla-cize'.",
        "The automobile brake was not invented until 1895. Before this, someone had to remain in the car at all times, driving in circles until passengers returned from their errands.",
        "Edmund Hillary, the first person to climb Mount Everest, did so accidentally while chasing a bird.",
        "The most poisonous fish in the world is the orange ruffy. Everything but its eyes are made of a deadly poison. The ruffy's eyes are composed of a less harmful, deadly poison.",
        "The occupation of court jester was invented accidentally, when a vassal's epilepsy was mistaken for capering.",
        "Before the Wright Brothers invented the airplane, anyone wanting to fly anywhere was required to eat 200 pounds of helium.",
        "Before the invention of scrambled eggs in 1912, the typical breakfast was either whole eggs still in the shell or scrambled rocks.",
        "During the Great Depression, the Tennessee Valley Authority outlawed pet rabbits, forcing many to hot glue-gun long ears onto their pet mice.",
        "The first person to prove that cow's milk is drinkable was very, very thirsty.",
        "Diamonds are made when coal is put under intense pressure. Diamonds put under intense pressure become foam pellets, commonly used today as packing material."]

lagcheck = text "✓ ✓ ✓"

tmyk = text "http://fc08.deviantart.net/fs71/f/2010/323/a/f/the_more_you_know_by_stathisnhx-d33639v.png"

hello = text "yes, this is bot"

inception = text . map toUpper . intersperse ' '

shatnerize = text . intercalate ". " . words

whoami = text "http://obscureinternet.com/wp-content/uploads/This-is-Data-Star-Trek-Funny.jpg"

shoot name = putStrLn $ "Die, "++name++"!"

galileo = text "figaro MAGNIFICOOOOO!"

konami = text "↑ ↑ ↓ ↓ ← → ← → Ⓑ Ⓐ START"

checkmate = text "(ノಠ益ಠ)ノ彡┻━┻"

czechmate = text "jste podváděl"

uptime = text "more than Shishichi!"

