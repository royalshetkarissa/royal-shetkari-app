const adminRepository = require('../repositories/adminRepository');
const { logActivity } = require('../utils/logger');
const AppError = require('../utils/AppError');

exports.getAllPosts = async (req, res, next) => {
  try {
    const posts = await adminRepository.getAllPosts();
    res.json({ posts, requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to fetch posts', 500));
  }
};

exports.getUsers = async (req, res, next) => {
  try {
    const users = await adminRepository.getAllUsers();
    res.json({ users, requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to fetch users', 500));
  }
};

exports.updateUserAccess = async (req, res, next) => {
  const { targetUserId, role, permissions, isAdmin } = req.body;
  try {
    await adminRepository.updateUserAccess(targetUserId, role, permissions, isAdmin);
    await logActivity(
      req.userId,
      'UPDATE_USER_ACCESS',
      'user',
      targetUserId,
      { role, permissions, isAdmin },
      req.id
    );
    res.json({ success: true, message: 'Access updated successfully', requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to update access', 500));
  }
};

exports.getTopCommenters = async (req, res, next) => {
  try {
    const topCommenters = await adminRepository.getTopCommenters();
    res.json({ topCommenters, requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to fetch stats', 500));
  }
};

exports.deleteUser = async (req, res, next) => {
  const { id } = req.params;
  try {
    const user = await adminRepository.getUserById(id);
    await adminRepository.deleteUser(id);
    await logActivity(req.userId, 'DELETE_USER', 'user', id, { deleted_user: user }, req.id);
    res.json({ success: true, message: 'User deleted permanently', requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to delete user', 500));
  }
};

exports.deletePost = async (req, res, next) => {
  const { id } = req.params;
  try {
    const post = await adminRepository.getPostById(id);
    await adminRepository.deletePost(id);
    await logActivity(req.userId, 'DELETE_POST', 'post', id, { deleted_post: post }, req.id);
    res.json({ success: true, message: 'Post deleted', requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to delete post', 500));
  }
};

exports.deleteComment = async (req, res, next) => {
  const { id } = req.params;
  try {
    const comment = await adminRepository.getCommentById(id);
    await adminRepository.deleteComment(id);
    await logActivity(
      req.userId,
      'DELETE_COMMENT',
      'comment',
      id,
      { deleted_comment: comment },
      req.id
    );
    res.json({ success: true, message: 'Comment deleted', requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to delete comment', 500));
  }
};

exports.getModerationLogs = async (req, res, next) => {
  try {
    const logs = await adminRepository.getModerationLogs();
    res.json({ logs, requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to fetch logs', 500));
  }
};

exports.getUserActivity = async (req, res, next) => {
  const { id } = req.params;
  try {
    const data = await adminRepository.getUserFullProfile(id);
    res.json({ ...data, requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to fetch user activity', 500));
  }
};

exports.getPostHistory = async (req, res, next) => {
  const { id } = req.params;
  try {
    const data = await adminRepository.getPostAuditHistory(id);
    res.json({
      success: true,
      ...data,
      requestId: req.id,
    });
  } catch (error) {
    next(new AppError('Failed to fetch post audit history', 500));
  }
};

exports.getUserComments = async (req, res, next) => {
  try {
    const comments = await adminRepository.getUserComments(req.params.id);
    res.json({ comments, requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to fetch comments', 500));
  }
};
