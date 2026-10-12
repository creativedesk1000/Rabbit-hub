import { useState, useEffect } from 'react'
import { motion as Motion, AnimatePresence } from 'framer-motion'
import { Menu, X, Instagram, Facebook, LocateIcon, Phone, Mail } from 'lucide-react'

const Navbar = () => {
    const [isOpen, setIsOpen] = useState(false)
    const [scrolled, setScrolled] = useState(false)

    useEffect(() => {
        const handleScroll = () => {
            setScrolled(window.scrollY > 50)
        }
        window.addEventListener('scroll', handleScroll)
        return () => window.removeEventListener('scroll', handleScroll)
    }, [])

    const navLinks = [
        { name: 'Home', href: '#home' },
        { name: 'App', href: '#app' },
        { name: 'Breeds', href: '#breeds' },
        { name: 'For Sale', href: '#sale' },
        { name: 'Gallery', href: '#gallery' },
        { name: 'Guides', href: '#guides' },
        { name: 'About', href: '#about' },
        { name: 'Contact', href: '#contact' },
    ]

    return (
        <nav className={`fixed w-full z-50 transition-all duration-300 ${scrolled ? 'bg-white/80 backdrop-blur-md py-4 shadow-sm' : 'bg-transparent py-6'}`}>
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center">
                    <a href="#home" className="flex-shrink-0 flex items-center" aria-label="Rabbit Hub home">
                        <img src="/rabbit-hub-logo.png" alt="Rabbit Hub" className="h-12 w-auto max-w-[190px] object-contain" />
                    </a>

                    <div className="hidden md:block">
                        <div className="ml-10 flex items-baseline space-x-8">
                            {navLinks.map((link) => (
                                <a
                                    key={link.name}
                                    href={link.href}
                                    className="text-primary-dark hover:text-primary px-3 py-2 text-sm font-medium transition-colors duration-200"
                                >
                                    {link.name}
                                </a>
                            ))}
                            <a href="#contact" className="btn-primary py-2 px-6 text-sm">
                                Get Started
                            </a>
                        </div>
                    </div>

                    <div className="md:hidden flex items-center">
                        <button
                            onClick={() => setIsOpen(!isOpen)}
                            className="text-primary p-2 focus:outline-none"
                        >
                            {isOpen ? <X size={24} /> : <Menu size={24} />}
                        </button>
                    </div>
                </div>
            </div>

            <AnimatePresence>
                {isOpen && (
                    <Motion.div
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: 'auto' }}
                        exit={{ opacity: 0, height: 0 }}
                        className="md:hidden bg-white border-b border-sand-200 overflow-hidden"
                    >
                        <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3">
                            {navLinks.map((link) => (
                                <a
                                    key={link.name}
                                    href={link.href}
                                    onClick={() => setIsOpen(false)}
                                    className="text-primary-dark hover:bg-sand-100 block px-3 py-4 text-base font-medium"
                                >
                                    {link.name}
                                </a>
                            ))}
                            <div className="pt-4 pb-2 px-3">
                                <a href="#contact" className="btn-primary w-full inline-block text-center py-3">
                                    Contact Us
                                </a>
                            </div>
                        </div>
                    </Motion.div>
                )}
            </AnimatePresence>
        </nav>
    )
}

const Footer = () => {
    return (
        <footer className="bg-primary-dark text-white pt-20 pb-10">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 md:grid-cols-4 gap-12">
                <div className="space-y-6">
                    <a href="#home" aria-label="Rabbit Hub home">
                        <img src="/rabbit-hub-logo.png" alt="Rabbit Hub" className="h-16 w-auto max-w-[240px] object-contain object-left" />
                    </a>
                    <p className="text-sand-200 text-sm leading-relaxed">
                        Premium breeding rabbits raised with ethical standards and professional care. Your trusted partner in high-end rabbit farming.
                    </p>
                    <div className="flex space-x-4">
                        <a href="https://www.instagram.com/rabbits_hub1000/" target="_blank" rel="noreferrer" className="p-2 bg-white/10 rounded-full hover:bg-primary transition-colors">
                            <Instagram size={18} />
                        </a>
                        <a href="#" className="p-2 bg-white/10 rounded-full hover:bg-primary transition-colors">
                            <Facebook size={18} />
                        </a>
                        <a href="https://wa.me/923170479205" target="_blank" rel="noreferrer" className="p-2 bg-white/10 rounded-full hover:bg-primary transition-colors">
                            <Phone size={18} />
                        </a>
                    </div>
                </div>

                <div>
                    <h4 className="font-serif text-lg font-bold mb-6">Quick Links</h4>
                    <ul className="space-y-4 text-sm text-sand-200">
                        <li><a href="#home" className="hover:text-white transition-colors">Home</a></li>
                        <li><a href="#breeds" className="hover:text-white transition-colors">Our Breeds</a></li>
                        <li><a href="#sale" className="hover:text-white transition-colors">Rabbits for Sale</a></li>
                        <li><a href="#gallery" className="hover:text-white transition-colors">Farm Gallery</a></li>
                        <li><a href="#about" className="hover:text-white transition-colors">About Us</a></li>
                    </ul>
                </div>

                <div>
                    <h4 className="font-serif text-lg font-bold mb-6">Resources</h4>
                    <ul className="space-y-4 text-sm text-sand-200">
                        <li><a href="#guides" className="hover:text-white transition-colors">Care Guides</a></li>
                        <li><a href="#" className="hover:text-white transition-colors">Breeding Tips</a></li>
                        <li><a href="#" className="hover:text-white transition-colors">Nutrition Info</a></li>
                        <li><a href="#" className="hover:text-white transition-colors">Support</a></li>
                    </ul>
                </div>

                <div>
                    <h4 className="font-serif text-lg font-bold mb-6">Contact Us</h4>
                    <ul className="space-y-4 text-sm text-sand-200">
                        <li className="flex items-start space-x-3">
                            <LocateIcon size={18} className="mt-1 flex-shrink-0" />
                            <span>Wah Cantt, Pakistan</span>
                        </li>
                        <li className="flex items-center space-x-3">
                            <Mail size={18} className="flex-shrink-0" />
                            <span>contact@rabbithub.com</span>
                        </li>
                        <li className="flex items-center space-x-3">
                            <Phone size={18} className="flex-shrink-0" />
                            <span>03170479205</span>
                        </li>
                    </ul>
                </div>
            </div>
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-20 pt-8 border-t border-white/10 text-center text-sm text-sand-200">
                <p>© {new Date().getFullYear()} Rabbit Hub. All rights reserved.</p>
            </div>
        </footer>
    )
}

export { Navbar, Footer }
