import { motion as Motion } from 'framer-motion'
import SectionHeading from './SectionHeading'
import { Info, ShoppingCart, Weight, Ruler } from 'lucide-react'
import { cn } from '../lib/utils'

// Import local images
import f1 from '../assets/images/f1.jpeg'
import f2 from '../assets/images/f2.jpeg'
import c2 from '../assets/images/c2.jpeg'
import c3 from '../assets/images/c3.jpeg'
import b2 from '../assets/images/b2.jpeg'
import b3 from '../assets/images/b3.jpeg'
import n2 from '../assets/images/n2.jpeg'
import imagesAdult from '../assets/images/images.jpeg'

const breeds = [
    {
        name: "Chinchilla Rabbit",
        weight: "2.5 - 4.5 kg",
        category: "Breeding / Pet",
        image: b2,
        description: "Known for their incredibly soft, slate-blue fur and docile nature. Excellent for high-end breeding programs."
    },
    {
        name: "New Zealand White",
        weight: "4.0 - 5.5 kg",
        category: "Meat / Breeding",
        image: imagesAdult,
        description: "The gold standard for meat production. Robust, healthy, and highly productive breeding pairs and adults."
    },
    {
        name: "Flemish Giant",
        weight: "6.0 - 10.0+ kg",
        category: "Show / Breeding",
        image: f1,
        description: "The 'Gentle Giant' of the rabbit world. Impressive size and calm temperament, perfect for exhibitions."
    }
]

const forSale = [
    {
        id: 1,
        breed: "Checkered Giant",
        age: "5 Months",
        weight: "3.8 kg",
        price: "$140",
        image: c2,
        status: "Available"
    },
    {
        id: 2,
        breed: "Chinchilla Kit",
        age: "4 Months",
        weight: "2.2 kg",
        price: "$150",
        image: b3,
        status: "Reserved"
    },
    {
        id: 3,
        breed: "New Zealand White",
        age: "6 Months",
        weight: "4.5 kg",
        price: "$110",
        image: n2,
        status: "Available"
    }
]

const BreedsSection = () => {
    return (
        <section id="breeds" className="py-24 bg-sand-50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <SectionHeading
                    title="Premium Rabbit Breeds"
                    subtitle="Our Specialized Selection"
                />

                <div className="grid md:grid-cols-3 gap-8">
                    {breeds.map((breed, idx) => (
                        <Motion.div
                            key={breed.name}
                            initial={{ opacity: 0, y: 30 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: idx * 0.1, duration: 0.6 }}
                            className="ui-card group"
                        >
                            <div className="relative overflow-hidden h-64">
                                <img
                                    src={breed.image}
                                    alt={breed.name}
                                    className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                                />
                                <div className="absolute inset-0 bg-gradient-to-t from-primary/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                            </div>
                            <div className="p-8">
                                <div className="flex justify-between items-start mb-4">
                                    <h3 className="text-xl font-bold font-serif text-primary-dark">{breed.name}</h3>
                                    <span className="bg-sand-100 text-primary-dark text-[10px] font-bold px-2 py-1 rounded uppercase tracking-wider">{breed.category}</span>
                                </div>
                                <p className="text-sm text-gray-500 mb-6 leading-relaxed">
                                    {breed.description}
                                </p>
                                <div className="flex items-center text-sm text-primary mb-6 space-x-4">
                                    <div className="flex items-center space-x-1">
                                        <Weight size={14} />
                                        <span className="font-semibold">{breed.weight}</span>
                                    </div>
                                </div>
                                <button className="flex min-h-11 w-full items-center justify-center rounded-xl border border-sand-200 bg-white px-4 py-2.5 text-sm font-semibold text-primary-dark transition-all duration-200 hover:border-primary hover:bg-primary hover:text-white active:scale-[0.98] group/btn">
                                    View Details <Info className="ml-2 opacity-0 group-hover/btn:opacity-100 -translate-x-2 group-hover/btn:translate-x-0 transition-all" size={16} />
                                </button>
                            </div>
                        </Motion.div>
                    ))}
                </div>
            </div>
        </section>
    )
}

const ForSaleSection = () => {
    return (
        <section id="sale" className="py-24 bg-white">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <SectionHeading
                    title="Rabbits For Sale"
                    subtitle="Start Your Breeding Journey"
                />

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
                    {forSale.map((item, idx) => (
                        <Motion.div
                            key={item.id}
                            initial={{ opacity: 0, scale: 0.95 }}
                            whileInView={{ opacity: 1, scale: 1 }}
                            viewport={{ once: true }}
                            transition={{ delay: idx * 0.1 }}
                            className="ui-card relative group"
                        >
                            <div className="absolute top-4 right-4 z-10">
                                <span className={cn(
                                    "px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest",
                                    item.status === 'Available' ? "bg-green-100 text-green-700" : "bg-orange-100 text-orange-700"
                                )}>
                                    {item.status}
                                </span>
                            </div>

                            <div className="h-72 overflow-hidden">
                                <img
                                    src={item.image}
                                    alt={item.breed}
                                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                                />
                            </div>

                            <div className="p-6">
                                <h4 className="text-lg font-bold font-serif text-primary-dark mb-1">{item.breed}</h4>
                                <div className="flex items-center text-xs text-gray-400 space-x-3 mb-4">
                                    <span className="flex items-center"><Ruler size={12} className="mr-1" /> {item.age}</span>
                                    <span className="flex items-center"><Weight size={12} className="mr-1" /> {item.weight}</span>
                                </div>

                                <div className="flex items-center justify-between mt-6 pt-6 border-t border-sand-100">
                                    <span className="text-2xl font-bold text-primary">{item.price}</span>
                                    <button className="flex min-h-11 items-center space-x-2 rounded-xl bg-gradient-to-r from-primary to-primary-light px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all duration-200 hover:-translate-y-0.5 hover:shadow-md active:scale-[0.98]">
                                        <ShoppingCart size={16} />
                                        <span>Contact to Buy</span>
                                    </button>
                                </div>
                            </div>
                        </Motion.div>
                    ))}
                </div>

                <div className="mt-16 text-center">
                    <p className="text-gray-400 text-sm mb-6">Need a custom breeding pair or bulk order?</p>
                    <a href="#contact" className="btn-secondary">Request Custom Order</a>
                </div>
            </div>
        </section>
    )
}

export { BreedsSection, ForSaleSection }
