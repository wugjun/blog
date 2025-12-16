---
title: "JAVA在线测试"
date: 2025-11-28
description: "Java 核心知识单选题练习"
lead: "以考促学，查漏补缺"
disable_comments: false # Optional, disable Disqus comments if true
authorbox: true # Optional, enable authorbox for specific post
toc: true # Optional, enable Table of Contents for specific post
mathjax: true # Optional, enable MathJax for specific post
categories:
  - "编程语言"
tags:
  - "java"
  - "面试题"
menu: 
  main:
    weight: 8 # Optional, add page to a menu. Options: main, side, footer
draft: true
---

[◀ 返回](/编程语言/编程语言-剑法篇/)

<section class="ai-quiz-section" data-ai-quiz-root data-ai-quiz-endpoint="http://qiaopan.tech:18080/api/v1/assistant/">
  <h2 class="ai-quiz-title">即时生成 AI 考题</h2>
  <p class="ai-quiz-desc">点击按钮即可调用本地大模型接口，自动生成新的考试题并追加到页面。</p>
  <div class="ai-quiz-controls">
    <div class="ai-quiz-control-group">
      <label for="ai-quiz-difficulty-page">难度：</label>
      <select id="ai-quiz-difficulty-page" class="ai-quiz-select" data-ai-quiz-param="difficulty">
        <option value="简单">简单</option>
        <option value="中等" selected>中等</option>
        <option value="困难">困难</option>
      </select>
    </div>
    <div class="ai-quiz-control-group">
      <label for="ai-quiz-count-page">数量：</label>
      <select id="ai-quiz-count-page" class="ai-quiz-select" data-ai-quiz-param="count">
        <option value="1">1 题</option>
        <option value="3" selected>3 题</option>
        <option value="5">5 题</option>
        <option value="10">10 题</option>
      </select>
    </div>
  </div>
  <div class="ai-quiz-actions">
    <button class="ai-quiz-button ai-quiz-floating-button" data-ai-quiz-trigger>“AI 考题”继续生成</button>
    <span class="ai-quiz-status" data-ai-quiz-status></span>
  </div>
  <div class="ai-quiz-results" data-ai-quiz-results></div>
</section>


[◀ 返回](/编程语言/编程语言-剑法篇/)