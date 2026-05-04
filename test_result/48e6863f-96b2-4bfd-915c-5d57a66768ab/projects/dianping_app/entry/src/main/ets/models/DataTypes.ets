// Shared data type classes for the Dianping app

// HomePage types
export class CategoryItem {
  name: string;
  icon: string;
  color: string;

  constructor(name: string, icon: string, color: string) {
    this.name = name;
    this.icon = icon;
    this.color = color;
  }
}

export class RecommendationItem {
  name: string;
  rating: string;
  price: string;
  tags: string[];
  image: string;

  constructor(name: string, rating: string, price: string, tags: string[], image: string) {
    this.name = name;
    this.rating = rating;
    this.price = price;
    this.tags = tags;
    this.image = image;
  }
}

// FoodListPage types
export class FoodItem {
  id: number;
  name: string;
  image: string;
  rating: string;
  reviewCount: number;
  avgPrice: string;
  category: string;
  tags: string[];
  distance: string;
  address: string;
  isFeatured: boolean;

  constructor(id: number, name: string, image: string, rating: string, reviewCount: number,
    avgPrice: string, category: string, tags: string[], distance: string, address: string,
    isFeatured: boolean) {
    this.id = id;
    this.name = name;
    this.image = image;
    this.rating = rating;
    this.reviewCount = reviewCount;
    this.avgPrice = avgPrice;
    this.category = category;
    this.tags = tags;
    this.distance = distance;
    this.address = address;
    this.isFeatured = isFeatured;
  }
}

// MapPage types
export class POIMarker {
  label: string;
  score: string;
  icon: string;
  x: number;
  y: number;

  constructor(label: string, score: string, icon: string, x: number, y: number) {
    this.label = label;
    this.score = score;
    this.icon = icon;
    this.x = x;
    this.y = y;
  }
}

export class POICard {
  title: string;
  rating: string;
  reviewCount: string;
  price: string;
  tags: string[];
  distance: string;
  badge: string;
  rankInfo: string;

  constructor(title: string, rating: string, reviewCount: string, price: string,
    tags: string[], distance: string, badge: string, rankInfo: string) {
    this.title = title;
    this.rating = rating;
    this.reviewCount = reviewCount;
    this.price = price;
    this.tags = tags;
    this.distance = distance;
    this.badge = badge;
    this.rankInfo = rankInfo;
  }
}

// MessagePage types
export class MessageItem {
  id: string;
  avatar: string;
  name: string;
  lastMessage: string;
  time: string;
  unreadCount: number;

  constructor(id: string, avatar: string, name: string, lastMessage: string,
    time: string, unreadCount: number) {
    this.id = id;
    this.avatar = avatar;
    this.name = name;
    this.lastMessage = lastMessage;
    this.time = time;
    this.unreadCount = unreadCount;
  }
}

// CheckinPage types
export class StreakReward {
  day: number;
  icon: string;
  points: number;
  label: string;
  achieved: boolean;

  constructor(day: number, icon: string, points: number, label: string, achieved: boolean) {
    this.day = day;
    this.icon = icon;
    this.points = points;
    this.label = label;
    this.achieved = achieved;
  }
}

// ProfilePage types
export class MenuItemData {
  icon: string;
  label: string;
  route: string;

  constructor(icon: string, label: string, route: string) {
    this.icon = icon;
    this.label = label;
    this.route = route;
  }
}

// ActionHubPage types
export class ActionHubItem {
  id: string;
  icon: string;
  title: string;
  subtitle: string;
  badge: string;

  constructor(id: string, icon: string, title: string, subtitle: string, badge: string) {
    this.id = id;
    this.icon = icon;
    this.title = title;
    this.subtitle = subtitle;
    this.badge = badge;
  }
}

export class ActionItemData {
  icon: string;
  label: string;
  count: string;
  color: string;

  constructor(icon: string, label: string, count: string, color: string) {
    this.icon = icon;
    this.label = label;
    this.count = count;
    this.color = color;
  }
}

export class ActivityMsgData {
  id: string;
  avatar: string;
  name: string;
  action: string;
  target: string;
  time: string;
  liked: boolean;

  constructor(id: string, avatar: string, name: string, action: string,
    target: string, time: string, liked: boolean) {
    this.id = id;
    this.avatar = avatar;
    this.name = name;
    this.action = action;
    this.target = target;
    this.time = time;
    this.liked = liked;
  }
}
