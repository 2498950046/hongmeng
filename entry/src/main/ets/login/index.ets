// 用户接口
export interface User {
  user_id: string;
  nickname: string;
  avatar_url: string;
  create_time: number;
}

// 收藏接口
export interface Collection {
  collection_id: string;
  user_id: string;
  target_id: string;
  type: number;
}

// 餐厅接口
export interface Restaurant {
  restaurant_id: string;
  name: string;
  category: string;
  address: string;
  latitude: number;
  longitude: number;
  rating: number;
  cover_url: string;
}

// 帖子接口
export interface Post {
  post_id: string;
  user_id: string;
  restaurant_id: string;
  content: string;
  image_urls: string;
  likes_count: number;
  publish_time: number;
}

// 收藏项接口（用于页面显示）
export interface CollectionItem {
  id: string;
  name: string;
  type: number;
  image?: string;
  rating?: number;
  address?: string;
}
