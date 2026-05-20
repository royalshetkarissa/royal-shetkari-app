const postRepository = require('../repositories/postRepository');
const cache = require('../utils/cache');

class PostService {
  async createPost(data) {
    const post = await postRepository.create(data);
    // Invalidate ALL post list caches for immediate global visibility
    await cache.invalidatePattern('posts:list:*');
    return post;
  }

  async getPosts(filters) {
    const cacheKey = `posts:list:${JSON.stringify(filters)}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const posts = await postRepository.findAll(filters);
    await cache.set(cacheKey, posts, 300); // 5 min cache
    return posts;
  }

  async getPostById(id) {
    const cacheKey = `post:detail:${id}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const post = await postRepository.findById(id);
    if (post) await cache.set(cacheKey, post, 600); // 10 min cache
    return post;
  }

  async incrementViews(id) {
    await postRepository.incrementViews(id);
    // No need to invalidate cache immediately as views are high-frequency
  }

  async incrementWpClicks(id) {
    await postRepository.incrementWpClicks(id);
  }

  async incrementCallClicks(id) {
    await postRepository.incrementCallClicks(id);
  }

  async toggleLike(userId, postId) {
    const existingLike = await postRepository.findLike(userId, postId);
    let result;
    if (existingLike) {
      await postRepository.removeLike(userId, postId);
      result = false;
    } else {
      await postRepository.addLike(userId, postId);
      result = true;
    }
    await cache.del(`post:detail:${postId}`);
    return result;
  }

  async toggleSave(userId, postId) {
    const existingSave = await postRepository.findSave(userId, postId);
    let result;
    if (existingSave) {
      await postRepository.removeSave(userId, postId);
      result = false;
    } else {
      await postRepository.addSave(userId, postId);
      result = true;
    }
    await cache.del(`post:detail:${postId}`);
    return result;
  }

  async getComments(postId) {
    const cacheKey = `post:comments:${postId}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const comments = await postRepository.getComments(postId);
    await cache.set(cacheKey, comments, 300);
    return comments;
  }

  async addComment(userId, postId, content) {
    const comment = await postRepository.addComment(userId, postId, content);
    await cache.del(`post:detail:${postId}`);
    await cache.del(`post:comments:${postId}`);
    return comment;
  }

  async softDeletePost(userId, postId) {
    const post = await postRepository.updateStatus(postId, userId, 'deleted');
    if (post) {
      await cache.del(`post:detail:${postId}`);
      await cache.invalidatePattern(`posts:list:*`);
    }
    return post;
  }

  async updatePost(postId, userId, data) {
    const currentPost = await postRepository.findById(postId);
    if (!currentPost || currentPost.user_id !== userId) return null;
    
    const post = await postRepository.update(postId, userId, {
      ...data,
      oldPrice: currentPost.price
    });
    
    if (post) {
      await cache.del(`post:detail:${postId}`);
      await cache.invalidatePattern(`posts:list:*`);
    }
    return post;
  }

  async getUserPosts(userId, userMobile) {
    return await postRepository.findUserPosts(userId, userMobile);
  }

  async getUserSocialStats(userId) {
    const cacheKey = `user:stats:${userId}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const stats = await postRepository.getUserSocialStats(userId);
    await cache.set(cacheKey, stats, 600);
    return stats;
  }

  async getSavedPosts(userId) {
    return await postRepository.getSavedPosts(userId);
  }
}

module.exports = new PostService();
