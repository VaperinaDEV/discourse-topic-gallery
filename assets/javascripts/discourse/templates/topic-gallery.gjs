import TopicGalleryGrid from "../components/topic-gallery-grid";

<template>
  <div class="topic-gallery-page">
    <div class="topic-gallery-header">
      <h1>{{@model.title}}</h1>
      <p class="image-count">{{@model.images.length}} images</p>
    </div>

    <TopicGalleryGrid @images={{@model.images}} />
  </div>
</template>
