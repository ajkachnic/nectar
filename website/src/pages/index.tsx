import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <>
      <div className={styles.warningBanner}>
        <p>nectar is in very early stages - see <a href="#current-progress">current progress</a>, and <a href="#future-goals">future plans</a></p>
      </div>
      <header className={clsx('hero hero--primary', styles.heroBanner)}>
        <div className="container">
          <h1 className={styles.title}>{siteConfig.title}</h1>
          <p className="hero__subtitle">{siteConfig.tagline}</p>
          <div className={styles.buttons}>
            <Link
              className={clsx("button", "button--lg", styles.heroButton)}
              to="/docs/basics/setup">
              Get Started
            </Link>
          </div>
        </div>
      </header>
      <section className={styles.copyMain}>
        <div className={styles.copyInner}>
          <div className={styles.copySection}>
            <h2>Tell me more</h2>
            <p>Audio programming can get very complicated, very quickly. Just to develop a simple plugin, you need to worry about different operating systems and underlying plugin formats. Tools like <a href="https://juce.com">JUCE</a> simplify this workflow, but not without tradeoffs.</p>

            <p>Nectar is a platform designed to take advantage of Zig's comptime capabilities, in order to create a development experience like no other. We aim to empower users, not slow them down.</p>
          </div>

          <div className={styles.copySection}>
            <h2 id="current-progress">Current Progress</h2>
            <ul>
              <li>VST2 wrapper is implemented</li>
              <li>Cross-platform abstractions like Plugin, Parameters, etc, are written</li>
              <li>Basic examples are implemented</li>
            </ul>
          </div>

          <div className={styles.copySection}>
            <h2 id="future-goals">Future Goals</h2>
            <p>In no particular order:</p>
            <ul>
              <li>Write lots of documentation, tutorials, and guides</li>
              <li>Implement abstractions for CLAP, VST3, and maybe LV2</li>
              <li>Implement a fully featured DSP library, with complete test coverage, and SIMD optimizations</li>
              <li>Implement a declarative GUI toolkit, with features like styling and input binding</li>
            </ul>
          </div>
        </div>
      </section>
    </>
  );
}

export default function Home(): JSX.Element {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title}`}
      description={`${siteConfig.tagline}`}>
      <HomepageHeader />
      <main>
        {/* <HomepageFeatures /> */}
      </main>
    </Layout>
  );
}
