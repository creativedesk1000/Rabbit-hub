import { motion as Motion } from 'framer-motion'
import SectionHeading from './SectionHeading'
import { BookOpen, Sprout, HeartPulse, Home } from 'lucide-react'

// Import local assets
import f2 from '../assets/images/f2.jpeg'
import c3 from '../assets/images/c3.jpeg'
import b4 from '../assets/images/b4.jpeg'
import n1 from '../assets/images/n1.jpeg'
import b1 from '../assets/images/b1.jpeg'
import rabbitVideo from '../assets/images/c1.mp4'

const galleryImages = [
    { url: f2, span: "row-span-2", type: 'image' },
    { url: c3, span: "", type: 'image' },
    { url: rabbitVideo, span: "col-span-2 row-span-2", type: 'video' },
    { url: b4, span: "", type: 'image' },
    { url: n1, span: "", type: 'image' },
    { url: b1, span: "", type: 'image' },
]

const guides = [
    {
        title: "Rabbit Feeding Guide",
        excerpt: "Learn the secrets to optimal nutrition for healthy, energetic breeding rabbits.",
        icon: <Sprout size={32} />,
        color: "bg-green-50",
        iconColor: "text-green-600"
    },
    {
        title: "Breeding Best Practices",
        excerpt: "Expert advice on managing breeding pairs and ensuring successful kits.",
        icon: <BookOpen size={32} />,
        color: "bg-blue-50",
        iconColor: "text-blue-600"
    },
    {
        title: "Rabbit Health Care",
        excerpt: "Essential tips for disease prevention and maintaining farm hygiene standards.",
        icon: <HeartPulse size={32} />,
        color: "bg-red-50",
        iconColor: "text-red-600"
    },
    {
        title: "Housing & Cage Setup",
        excerpt: "Design the perfect environment for your rabbits to thrive and remain stress-free.",
        icon: <Home size={32} />,
        color: "bg-orange-50",
        iconColor: "text-orange-600"
    }
]

const GallerySection = () => {
    return (
        <section id="gallery" className="py-24 bg-sand-50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <SectionHeading
                    title="Farm Gallery"
                    subtitle="A Glimpse into Our World"
                />

                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 auto-rows-[200px]">
                    {galleryImages.map((item, idx) => (
                        <Motion.div
                            key={idx}
                            initial={{ opacity: 0, scale: 0.9 }}
                            whileInView={{ opacity: 1, scale: 1 }}
                            viewport={{ once: true }}
                            transition={{ delay: idx * 0.1 }}
                            className={`relative overflow-hidden group rounded-xl ${item.span}`}
                        >
                            {item.type === 'video' ? (
                                <video
                                    src={item.url}
                                    className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                                    autoPlay
                                    muted
                                    loop
                                    playsInline
                                />
                            ) : (
                                <img
                                    src={item.url}
                                    className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                                    alt={`Farm Gallery ${idx + 1}`}
                                />
                            )}
                            <div className="absolute inset-0 bg-primary/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none" />
                        </Motion.div>
                    ))}
                </div>
            </div>
        </section>
    )
}

const GuidesSection = () => {
    return (
        <section id="guides" className="py-24 bg-white">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <SectionHeading
                    title="Rabbit Care Guides"
                    subtitle="Expertise Shared for Your Success"
                />

                <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-8">
                    {guides.map((guide, idx) => (
                        <Motion.div
                            key={idx}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: idx * 0.1 }}
                            className="ui-card group p-8 hover:bg-sand-50"
                        >
                            <div className={`w-16 h-16 rounded-xl flex items-center justify-center mb-6 transition-transform group-hover:scale-110 ${guide.color} ${guide.iconColor}`}>
                                {guide.icon}
                            </div>
                            <h3 className="text-xl font-bold font-serif text-primary-dark mb-4">{guide.title}</h3>
                            <p className="text-sm text-gray-500 mb-8 leading-relaxed">
                                {guide.excerpt}
                            </p>
                            <button className="text-primary font-bold text-xs uppercase tracking-widest flex items-center group/btn">
                                Read Article <span className="ml-2 transition-transform group-hover/btn:translate-x-1">→</span>
                            </button>
                        </Motion.div>
                    ))}
                </div>
            </div>
        </section>
    )
}

export { GallerySection, GuidesSection }
