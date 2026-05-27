const postService = require('../services/postService');
const { logActivity } = require('../utils/logger');
const AppError = require('../utils/AppError');
const { addPostJob } = require('../jobs/postQueue');

const fs = require('fs').promises;
const { PutObjectCommand } = require('@aws-sdk/client-s3');
const s3Client = require('../config/b2');

exports.createPost = async (req, res, next) => {
  try {
    const {
      category,
      title,
      description,
      price,
      location,
      contact_mobile,
      latitude,
      longitude,
      animal_type,
      lactation,
      milk_per_day,
    } = req.body;
    const imageUrls = [];

    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        try {
          // If Backblaze credentials are configured, upload there
          if (process.env.B2_KEY_ID && process.env.B2_KEY_ID !== 'YOUR_KEY_ID') {
            const fileKey = `posts/${Date.now()}-${Math.random().toString(36).substring(2, 10)}-${file.filename}`;
            const fileBuffer = await fs.readFile(file.path);

            const uploadCommand = new PutObjectCommand({
              Bucket: process.env.B2_BUCKET || 'rsitapp-images',
              Key: fileKey,
              Body: fileBuffer,
              ContentType: file.mimetype,
            });
            await s3Client.send(uploadCommand);

            // Reference the secure proxy image URL
            imageUrls.push(`/api/image/${fileKey}`);

            // Delete local file to free up space
            await fs.unlink(file.path);
          } else {
            imageUrls.push(`/uploads/${file.filename}`);
          }
        } catch (uploadError) {
          console.error('Failed to upload image to B2, falling back to local:', uploadError);
          imageUrls.push(`/uploads/${file.filename}`);
        }
      }
    }

    const post = await postService.createPost({
      userId: req.userId,
      category,
      title,
      description,
      price,
      location,
      contact_mobile: contact_mobile || req.body.contact_number,
      images: imageUrls,
      image_url: imageUrls[0] || null,
      latitude,
      longitude,
      animal_type,
      lactation,
      milk_per_day,
    });

    // Background Jobs (Wrapped to prevent queue failures from blocking success response)
    try {
      await addPostJob('process-images', { postId: post.id, images: imageUrls });
      await addPostJob('send-notifications', { postId: post.id, title: post.title });
    } catch (queueError) {
      console.error('Failed to add post background jobs to queue:', queueError.message);
    }

    await logActivity(req.userId, 'CREATE_POST', 'post', post.id, { title, category }, req.id);
    res.status(201).json({ success: true, post, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.getPosts = async (req, res, next) => {
  try {
    const posts = await postService.getPosts(req.query);
    res.json({ success: true, posts });
  } catch (error) {
    next(error);
  }
};

exports.trackWpClick = async (req, res, next) => {
  try {
    await postService.incrementWpClicks(req.params.id);
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

exports.trackCallClick = async (req, res, next) => {
  try {
    await postService.incrementCallClicks(req.params.id);
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

exports.getPostDetails = async (req, res, next) => {
  try {
    const post = await postService.getPostById(req.params.id);
    if (!post) return next(new AppError('Post not found', 404));

    await postService.incrementViews(req.params.id);
    res.json({ success: true, post });
  } catch (error) {
    next(error);
  }
};

exports.likePost = async (req, res, next) => {
  try {
    const liked = await postService.toggleLike(req.userId, req.params.id);
    res.json({ success: true, liked });
  } catch (error) {
    next(error);
  }
};

exports.savePost = async (req, res, next) => {
  try {
    const saved = await postService.toggleSave(req.userId, req.params.id);
    res.json({ success: true, saved });
  } catch (error) {
    next(error);
  }
};

exports.getComments = async (req, res, next) => {
  try {
    const comments = await postService.getComments(req.params.id);
    res.json({ success: true, comments });
  } catch (error) {
    next(error);
  }
};

exports.addComment = async (req, res, next) => {
  try {
    const comment = await postService.addComment(req.userId, req.params.id, req.body.content);
    res.status(201).json({ success: true, comment });
  } catch (error) {
    next(error);
  }
};

exports.deletePost = async (req, res, next) => {
  try {
    const post = await postService.softDeletePost(req.userId, req.userMobile, req.params.id);
    if (!post) return next(new AppError('Post not found or unauthorized', 404));

    await logActivity(
      req.userId,
      'DELETE_POST',
      'post',
      req.params.id,
      { title: post.title },
      req.id
    );
    res.json({ success: true, message: 'Post moved to history', requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.updatePost = async (req, res, next) => {
  try {
    const post = await postService.updatePost(req.params.id, req.userId, req.userMobile, req.body);
    if (!post) return next(new AppError('Post not found or unauthorized', 404));

    await logActivity(
      req.userId,
      'POST_EDITED',
      'post',
      req.params.id,
      { title: post.title },
      req.id
    );
    res.json({ success: true, message: 'Post updated', post, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.getUserPosts = async (req, res, next) => {
  try {
    const posts = await postService.getUserPosts(req.userId, req.userMobile);
    res.json({ success: true, posts });
  } catch (error) {
    next(error);
  }
};

exports.getUserSocialStats = async (req, res, next) => {
  try {
    const stats = await postService.getUserSocialStats(req.userId);
    res.json({ success: true, stats });
  } catch (error) {
    next(error);
  }
};

exports.getSavedPosts = async (req, res, next) => {
  try {
    const posts = await postService.getSavedPosts(req.userId);
    res.json({ success: true, posts });
  } catch (error) {
    next(error);
  }
};
