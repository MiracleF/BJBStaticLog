//
//  RealTimeLogManager.m
//  LineCloud
//
//  Created by 李杰峰 on 2021/1/16.
//

#import "RealTimeLogManager.h"
#import "RealTimeLogWindow.h"
#import "LogManager.h"

static BOOL windowOpen = NO;

@interface RealTimeLogManager () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UIViewController *miniVC;
@property (strong, nonatomic) RealTimeLogWindow *miniWindow;
@property (strong, nonatomic) NSMutableArray *cellLogs;

@end

@implementation RealTimeLogManager

+ (instancetype)shareInstance
{
    static RealTimeLogManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RealTimeLogManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createMiniWindowBeforeAllView];
    }
    return self;
}

- (void)createMiniWindowBeforeAllView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.miniVC = [[UIViewController alloc] init];
        self.miniVC.view.backgroundColor = [UIColor whiteColor];
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height - 20) style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.tag = 10000;
        tableView.hidden = YES;
        [self.miniVC.view addSubview:tableView];
        
        UILabel *logLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 20)];
        logLabel.tag = 9999;
        logLabel.backgroundColor = [UIColor clearColor];
        logLabel.font = [UIFont systemFontOfSize:14];
        [self.miniVC.view addSubview:logLabel];
        
        self.miniWindow = [[RealTimeLogWindow alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 20)];
        //    self.miniWindow = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
        [self.miniWindow setWindowLevel:UIWindowLevelStatusBar + 10];
        [self.miniWindow setBackgroundColor:[UIColor clearColor]];
        [self.miniWindow setRootViewController:self.miniVC];
        self.miniWindow.hidden = NO;
//        [self.miniWindow makeKeyAndVisible];
        
//        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOnWindow:)];
//        pan.minimumNumberOfTouches = 2;
//        pan.maximumNumberOfTouches = 2;
//        [self.miniWindow addGestureRecognizer:pan];
//        self.miniWindow.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tapOnLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnMsgLabel:)];
        [logLabel addGestureRecognizer:tapOnLabel];
        logLabel.userInteractionEnabled = YES;
    });
    
}

- (void)logWithType:(enum logType)type andModule:(NSString *)module andLogStr:(NSString*)logStr, ...
{

    NSMutableString* parmaStr = [NSMutableString string];
    // 声明一个参数指针
    va_list paramList;
    // 获取参数地址，将paramList指向logStr
    va_start(paramList, logStr);
    id arg = logStr;
    
    @try {
        // 遍历参数列表
        while (arg) {
            [parmaStr appendString:arg];
            // 指向下一个参数，后面是参数类似
            arg = va_arg(paramList, NSString*);
        }
        
    } @catch (NSException *exception) {
        
        [parmaStr appendString:@"【记录日志异常】"];
    } @finally {
        
        // 将参数列表指针置空
        va_end(paramList);
    }
    
    LLog(module, parmaStr);

    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *logLabel = [self.miniVC.view viewWithTag:9999];
        if (type == kSuccess) {
            logLabel.backgroundColor = [UIColor systemGreenColor];
        } else if (type == kFail) {
            logLabel.backgroundColor = [UIColor systemRedColor];
        }
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        //设定时间格式,这里可以设置成自己需要的格式
        [dateFormatter setDateFormat:@"MM-dd HH:mm:ss"];
        //用[NSDate date]可以获取系统当前时间
        NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
        
        NSString *msg = [NSString stringWithFormat:@"%@:[%@]:%@", currentDateStr, module, parmaStr];
        
        logLabel.text = msg;
        
        if (!self->_cellLogs) {
            self->_cellLogs = [[NSMutableArray alloc] init];
        }
        
        if (self->_cellLogs.count > 100) {
            [self->_cellLogs removeObjectAtIndex:0];
        }
        
        [self->_cellLogs addObject:@{@"msg" : msg ,
                               @"type" : @(type)}];
        
        UITableView *tableview = [self.miniVC.view viewWithTag:10000];
        if (windowOpen) {
            [tableview reloadData];
        }
    });
}

- (void)panOnWindow:(UIPanGestureRecognizer *)panGesture
{
    CGPoint point = [panGesture translationInView:panGesture.view];
    panGesture.view.transform = CGAffineTransformMakeTranslation(point.x, point.y);
    panGesture.view.transform = CGAffineTransformTranslate(panGesture.view.transform, point.x, point.y);
    [panGesture setTranslation:point inView:panGesture.view];
    
    point = [panGesture translationInView:panGesture.view];

    panGesture.view.center = CGPointMake(panGesture.view.center.x+ point.x,panGesture.view.center.y+ point.y);

    [panGesture setTranslation:CGPointZero inView:panGesture.view];

}


- (void)tapOnMsgLabel:(UITapGestureRecognizer *)tapGesture
{
    if (windowOpen) {
        windowOpen = NO;
        self.miniWindow.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 20);
        UITableView *tableview = [self.miniVC.view viewWithTag:10000];
        tableview.hidden = YES;
    } else {
        windowOpen = YES;
        self.miniWindow.frame = [[UIScreen mainScreen] bounds];
        UITableView *tableview = [self.miniVC.view viewWithTag:10000];
        tableview.hidden = NO;
        [tableview reloadData];
    }
}

#pragma mark - tableview datasource and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!_cellLogs) {
        return 0;
    } else {
        return _cellLogs.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellName = @"logCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
    }
    NSDictionary *log = _cellLogs[indexPath.row];
    cell.textLabel.text = log[@"msg"];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    if ([log[@"type"] intValue] == kSuccess) {
        cell.backgroundColor = [UIColor systemGreenColor];
    } else if ([log[@"type"] intValue] == kFail) {
        cell.backgroundColor = [UIColor systemRedColor];
    }
    
    return cell;
    
}

@end
