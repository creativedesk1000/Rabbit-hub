import { motion as Motion } from 'framer-motion'
import { Download, Smartphone } from 'lucide-react'

const AppDownloadSection = () => (
    <section id="app" className="overflow-hidden bg-primary-dark py-20 text-white md:py-28">
        <div className="mx-auto grid max-w-7xl items-center gap-12 px-4 sm:px-6 lg:grid-cols-[1.15fr_0.85fr] lg:px-8">
            <Motion.div
                initial={{ opacity: 0, x: -24 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6 }}
            >
                <span className="mb-5 inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-sand-200">
                    <Smartphone size={15} />
                    Rabbit Hub for Android
                </span>
                <h2 className="mb-6 font-serif text-4xl leading-tight text-white md:text-5xl">
                    Rabbit Hub, right in your pocket.
                </h2>
                <p className="mb-8 max-w-xl text-base leading-relaxed text-white/75 md:text-lg">
                    Keep up with Rabbit Hub wherever you go. Download the Android app to explore the app experience on your phone.
                </p>
                <a
                    href="/rabbitub.apk"
                    download="Rabbit-Hub.apk"
                    className="inline-flex min-h-14 items-center justify-center gap-3 rounded-xl bg-gradient-to-r from-white to-sand-100 px-8 py-4 text-base font-bold text-primary-dark shadow-[0_12px_28px_rgba(0,0,0,0.16)] transition-all duration-200 hover:-translate-y-0.5 hover:shadow-[0_16px_32px_rgba(0,0,0,0.20)] active:scale-[0.98]"
                >
                    <Download size={20} />
                    Download Android APK
                </a>
                <p className="mt-4 text-sm text-white/60">Android app · APK file</p>
            </Motion.div>

            <Motion.div
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.7 }}
                className="relative mx-auto w-full max-w-lg lg:translate-x-6"
            >
                <img
                    src="/app-branding-mockup.png"
                    alt="Rabbit Hub app icon and mobile home-screen mockup"
                    className="h-auto w-full rounded-3xl shadow-2xl"
                />
            </Motion.div>
        </div>
    </section>
)

export default AppDownloadSection
