import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <div className={styles.terminalWindow}>
          <div className={styles.terminalHeader}>
            <span className={styles.terminalDot} style={{background: '#FF5F56'}}></span>
            <span className={styles.terminalDot} style={{background: '#FFBD2E'}}></span>
            <span className={styles.terminalDot} style={{background: '#27CA40'}}></span>
            <span className={styles.terminalTitle}>iackathon ~ v1.0.0</span>
          </div>
          <div className={styles.terminalBody}>
            <p className={styles.terminalLine}>
              <span className={styles.terminalPrompt}>$</span> cat /etc/welcome
            </p>
            <Heading as="h1" className={styles.heroTitle}>
              {siteConfig.title}
            </Heading>
            <p className={styles.heroSubtitle}>{siteConfig.tagline}</p>
            <p className={styles.terminalLine}>
              <span className={styles.terminalPrompt}>$</span> ./start --guide
            </p>
          </div>
        </div>
        <div className={styles.buttons}>
          <Link
            className={clsx('button button--lg', styles.buttonPrimary)}
            to="/user-guide/introduction">
            Guide Utilisateur
          </Link>
          <Link
            className={clsx('button button--lg', styles.buttonSecondary)}
            to="/developer/architecture">
            Documentation Developpeur
          </Link>
        </div>
      </div>
    </header>
  );
}

type FeatureItem = {
  title: string;
  icon: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'IA 100% Locale',
    icon: '[ OFFLINE ]',
    description: (
      <>
        Aucune connexion requise. Vos donnees restent sur votre appareil.
        Confidentialite totale garantie avec inference locale.
      </>
    ),
  },
  {
    title: 'Modeles Gemma & DeepSeek',
    icon: '[ MODELS ]',
    description: (
      <>
        Support des modeles Gemma 3 (1B, 4B) et DeepSeek R1 avec mode reflexion.
        Choisissez selon vos besoins de performance.
      </>
    ),
  },
  {
    title: 'RAG Documents',
    icon: '[ RAG ]',
    description: (
      <>
        Interrogez vos documents PDF. Extraction automatique, chunking intelligent
        et recherche semantique integree.
      </>
    ),
  },
  {
    title: 'Vision Multimodale',
    icon: '[ VISION ]',
    description: (
      <>
        Analysez des images avec les modeles multimodaux. Description, extraction
        de texte et comprehension visuelle.
      </>
    ),
  },
  {
    title: 'Templates Prompts',
    icon: '[ TEMPLATES ]',
    description: (
      <>
        Creez et reutilisez des prompts personnalises. Variables dynamiques pour
        des workflows optimises.
      </>
    ),
  },
  {
    title: 'Open Source',
    icon: '[ MIT ]',
    description: (
      <>
        Code source ouvert sous licence MIT. Contribuez, modifiez et deployez
        selon vos besoins.
      </>
    ),
  },
];

function Feature({title, icon, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4', styles.featureCol)}>
      <div className={styles.featureCard}>
        <div className={styles.featureIcon}>{icon}</div>
        <Heading as="h3" className={styles.featureTitle}>{title}</Heading>
        <p className={styles.featureDescription}>{description}</p>
      </div>
    </div>
  );
}

function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className={styles.sectionHeader}>
          <span className={styles.terminalPrompt}>$</span> ls -la /features
        </div>
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

function QuickStart(): ReactNode {
  return (
    <section className={styles.quickStart}>
      <div className="container">
        <div className={styles.sectionHeader}>
          <span className={styles.terminalPrompt}>$</span> cat /docs/quickstart.md
        </div>
        <div className={styles.quickStartGrid}>
          <div className={styles.quickStartCard}>
            <div className={styles.stepNumber}>01</div>
            <h3>Installation</h3>
            <p>Telechargez l'APK depuis GitHub Releases ou compilez depuis les sources.</p>
            <code>flutter build apk --release</code>
          </div>
          <div className={styles.quickStartCard}>
            <div className={styles.stepNumber}>02</div>
            <h3>Selection du modele</h3>
            <p>Choisissez un modele adapte a votre appareil (1B pour appareils modestes).</p>
            <code>Gemma 3 1B | 4B | DeepSeek R1</code>
          </div>
          <div className={styles.quickStartCard}>
            <div className={styles.stepNumber}>03</div>
            <h3>Telechargement</h3>
            <p>Le modele est telecharge une seule fois et stocke localement.</p>
            <code>~1-4 Go selon le modele</code>
          </div>
          <div className={styles.quickStartCard}>
            <div className={styles.stepNumber}>04</div>
            <h3>Conversation</h3>
            <p>Commencez a discuter ! Tout fonctionne hors-ligne.</p>
            <code>100% local & prive</code>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="Documentation"
      description="Documentation officielle d'IAckathon - Assistant IA local propulse par Gemma">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <QuickStart />
      </main>
    </Layout>
  );
}
